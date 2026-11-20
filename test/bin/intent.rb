require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'

ROOT = File.expand_path('../..', __dir__)
SOURCE = ENV.fetch('INJECTOR_SOURCE', File.join(ROOT, 'src/injector.rb'))

FileUtils.mkdir_p(File.join(ROOT, 'test/tmp'))
Dir.mktmpdir('intent-', File.join(ROOT, 'test/tmp')) do |dir|
  app = File.join(dir, 'app')
  child = File.join(app, 'child')
  home = File.join(dir, 'package')
  FileUtils.mkdir_p([child, File.join(home, 'specifications'), File.join(home, 'gems/datadog-1.0.0/lib/datadog')])
  File.write(File.join(home, 'specifications/datadog-1.0.0.gemspec'), <<~RUBY)
    Gem::Specification.new do |s|
      s.name = 'datadog'
      s.version = '1.0.0'
      s.summary = 'Intent regression test double'
      s.authors = ['Test']
    end
  RUBY
  File.write(File.join(home, 'gems/datadog-1.0.0/lib/datadog/single_step_instrument.rb'), '$intent_instrumented = true')
  File.write(File.join(home, 'Gemfile.lock'), "GEM\n  specs:\n    datadog (1.0.0)\n\nPLATFORMS\n  ruby\n\nDEPENDENCIES\n  datadog\n")
  File.write(File.join(app, 'Gemfile'), "source 'https://rubygems.org'\n")
  File.write(File.join(app, 'Gemfile.lock'), "GEM\n  remote: https://rubygems.org/\n  specs:\n\nPLATFORMS\n  ruby\n\nDEPENDENCIES\n")
  forwarder = File.join(dir, 'forwarder')
  File.write(forwarder, "#!#{RbConfig.ruby}\nFile.open(ENV.fetch('INTENT_TELEMETRY'), 'a') { |f| f.puts STDIN.read }\n")
  FileUtils.chmod(0755, forwarder)
  env = {
    'RUBYOPT' => nil, 'BUNDLE_GEMFILE' => nil, 'BUNDLE_BIN_PATH' => nil,
    'BUNDLER_VERSION' => nil, 'RUBYGEMS_GEMDEPS' => nil,
    'BUNDLE_APP_CONFIG' => File.join(dir, 'config'),
    'DD_INTERNAL_RUBY_INJECTOR' => nil, 'DD_INTERNAL_RUBY_INJECTOR_PATCH' => nil,
    'DD_INTERNAL_RUBY_INJECTOR_GEM_HOME' => home,
    'DD_INTERNAL_RUBY_INJECTOR_LOCKFILE' => File.join(home, 'Gemfile.lock'),
    'DD_TELEMETRY_FORWARDER_PATH' => forwarder,
    'INTENT_TELEMETRY' => File.join(dir, 'telemetry'),
    'INTENT_APP' => app,
  }
  probe = <<~'RUBY'
    require 'json'
    puts JSON.generate(:gemfile => ENV['BUNDLE_GEMFILE'], :bundler => Gem.loaded_specs.key?('bundler'), :datadog => Gem.loaded_specs.key?('datadog'), :home => ENV['GEM_HOME'], :path => ENV['GEM_PATH'])
  RUBY
  [app, child].each { |path| File.write(File.join(path, 'probe.rb'), probe) }
  cwd = child
  failures = []
  check = lambda do |name, args, input, extra, injected, expected|
    %w[datadog.gemfile datadog.gemfile.lock].each { |f| FileUtils.rm_f(File.join(app, f)) }
    FileUtils.rm_f(env['INTENT_TELEMETRY'])
    vars = env.merge(extra)
    vars['RUBYOPT'] = "-r#{SOURCE}" if injected
    out, err, status = Open3.capture3(vars, *args, :stdin_data => input, :chdir => cwd)
    events = File.exist?(env['INTENT_TELEMETRY']) ? File.readlines(env['INTENT_TELEMETRY']).map { |l| JSON.parse(l) } : []
    begin
      raise "exit #{status.exitstatus}: #{err}" unless status.success?
      data = JSON.parse(out.lines.last)
      if [:naked, :library, :unbundled].include?(expected)
        raise 'generated Gemfile' if File.exist?(File.join(app, 'datadog.gemfile'))
        raise 'generated lockfile' if File.exist?(File.join(app, 'datadog.gemfile.lock'))
        raise "bundle activated: #{data}" if data['datadog'] || data['gemfile'] != extra['BUNDLE_GEMFILE']
        raise 'Bundler activated without a request' if expected == :naked && data['bundler']
        raise 'gem paths redirected' unless data['home'] == ENV['GEM_HOME'] && data['path'] == ENV['GEM_PATH']
        if injected
          reason = expected == :unbundled ? 'reason:bundler.unbundled' : 'reason:bundler.unrequested'
          raise "missing expected abort: #{events}" unless events.count { |e| e['points'].any? { |p| p['tags'].to_a.include?(reason) } } == 1
        end
      elsif expected == :preloaded
        raise 'injected an already active bundle' if data['datadog'] || File.exist?(File.join(app, 'datadog.gemfile'))
        raise 'missing already-active abort' unless events.any? { |e| e['points'].any? { |p| p['tags'].to_a.include?('reason:bundler.active') } }
      else
        raise "injection missing: #{data}" unless data['datadog'] && data['instrumented'] && data['gemfile'].end_with?('/datadog.gemfile')
        raise "missing success telemetry: #{events}" unless events.any? { |e| e['metadata']['result_class'] == 'success' }
        raise 'recursive injection' unless events.count { |e| e['metadata']['result_class'] == 'success' } == 1
        if expected == :exec
          raise "missing inherited completion: #{events}" unless events.any? { |e| e['metadata']['result_class'] == 'success_cached' }
          raise 'missing inherited skip flag' unless data['skip'] == 'false'
          raise 'missing inherited patch flag' if extra['BUNDLE_PATH'] && !data['patch']
        end
      end
      puts "PASS #{name}"
    rescue StandardError => e
      failures << name
      warn "FAIL #{name}: #{e.message}\n#{out}\n#{err}"
    end
  end
  [[['-e', probe], ''], [['probe.rb'], ''], [[], probe]].each do |args, input|
    [app, child].each do |path|
      cwd = path
      [false, true].each { |injected| check.call("naked #{args.first || 'stdin'} cwd=#{File.basename(cwd)} injected=#{injected}", [RbConfig.ruby, *args], input, {}, injected, :naked) }
    end
  end
  [
    { 'BUNDLE_GEMFILE' => File.join(app, 'Gemfile') },
    { 'BUNDLE_BIN_PATH' => '/hint' },
    { 'BUNDLE_PATH' => '/hint', 'BUNDLE_DEPLOYMENT' => 'true' },
    { 'DD_INTERNAL_RUBY_INJECTOR' => 'false' },
    { 'DD_INTERNAL_RUBY_INJECTOR_PATCH' => 'hint' },
    { 'DD_INTERNAL_RUBY_INJECTOR' => 'false', 'DD_INTERNAL_RUBY_INJECTOR_PATCH' => 'hint' },
  ].each do |extra|
    check.call("hint #{extra.keys.first}", [RbConfig.ruby, '-e', probe], '', extra, true, :naked)
  end
  File.write(File.join(child, 'bundle'), probe)
  check.call('a script named bundle is not intent', [RbConfig.ruby, 'bundle'], '', {}, true, :naked)
  check.call('require bundler only', [RbConfig.ruby, '-e', "require 'bundler'; #{probe}"], '', {}, true, :library)
  activation = <<~'RUBY'
    Bundler.setup
    require 'bundler/setup'
    raise 'require did not preserve its cache' unless require('bundler/setup') == false
    Bundler.setup(:default)
    Bundler.require
    require 'json'
    puts JSON.generate(:gemfile => ENV['BUNDLE_GEMFILE'], :datadog => Gem.loaded_specs.key?('datadog'), :instrumented => $intent_instrumented, :skip => ENV['DD_INTERNAL_RUBY_INJECTOR'], :patch => ENV['DD_INTERNAL_RUBY_INJECTOR_PATCH'])
  RUBY
  versions = Gem::Specification.find_all_by_name('bundler').map(&:version).uniq.select { |v| v >= Gem::Version.new('2.4') }
  boots = ["require 'bundler'; Bundler.setup", "require 'bundler/setup'"]
  boots += versions.map { |v| "gem 'bundler', '#{v}'; require 'bundler'; raise 'wrong version' unless Bundler::VERSION == '#{v}'; Bundler.setup" }
  boots.each do |boot|
    check.call("delayed #{boot}", [RbConfig.ruby, '-e', "raise 'bundle prepared before setup' if File.exist?(File.join(ENV.fetch('INTENT_APP'), 'datadog.gemfile')); #{boot}; #{activation}"], '', {}, true, :active)
  end
  check.call('command-line -r runs before RUBYOPT', [RbConfig.ruby, '-rbundler/setup', '-e', activation], '', {}, true, :preloaded)
  check.call('preloaded Bundler without setup', [RbConfig.ruby, '-rbundler', '-e', activation], '', {}, true, :active)
  check.call('Bundler autoload', [RbConfig.ruby, '-e', "autoload :Bundler, 'bundler'; #{activation}"], '', {}, true, :active)
  check.call('fork before setup', [RbConfig.ruby, '-e', "pid = fork { require 'bundler/setup'; #{activation} }; Process.wait(pid); exit $?.exitstatus"], '', {}, true, :active)
  check.call('concurrent setup', [RbConfig.ruby, '-e', "require 'bundler'; threads = 2.times.map { Thread.new { Bundler.setup } }; threads.each(&:value); #{activation}"], '', {}, true, :active)
  File.write(File.join(child, 'application.rb'), "#!/usr/bin/env ruby\n#{activation}")
  FileUtils.chmod(0755, File.join(child, 'application.rb'))
  bundle = Gem.bin_path('bundler', 'bundle')
  [{}, { 'BUNDLE_PATH' => File.join(app, 'vendor/bundle'), 'BUNDLE_DEPLOYMENT' => 'true' }].each do |extra|
    check.call("CLI exec #{extra}", [RbConfig.ruby, bundle, 'exec', RbConfig.ruby, 'application.rb'], '', extra, true, :exec)
    check.call("CLI load #{extra}", [RbConfig.ruby, bundle, 'exec', './application.rb'], '', extra, true, :active)
  end
  wrapper = File.join(RbConfig::CONFIG['bindir'], 'bundle')
  versions.each do |version|
    check.call("CLI explicit Bundler #{version}", [RbConfig.ruby, wrapper, "_#{version}_", 'exec', RbConfig.ruby, 'application.rb'], '', {}, true, :exec)
  end
  gemdeps = <<~'RUBY'
    require 'json'
    require 'datadog/single_step_instrument' if Gem.loaded_specs.key?('datadog')
    puts JSON.generate(:gemfile => ENV['BUNDLE_GEMFILE'], :datadog => Gem.loaded_specs.key?('datadog'), :instrumented => $intent_instrumented)
  RUBY
  ['-', File.join(app, 'Gemfile')].each do |path|
    extra = { 'RUBYGEMS_GEMDEPS' => path }
    out, err, status = Open3.capture3(env.merge(extra), RbConfig.ruby, '-e', 'puts !!Gem.gemdeps', :chdir => cwd)
    raise err unless status.success?
    if out.strip == 'true'
      check.call("automatic gemdeps #{path}", [RbConfig.ruby, '-e', gemdeps], '', extra, true, :active)
    else
      check.call("inactive gemdeps environment #{path}", [RbConfig.ruby, '-e', probe], '', extra, true, :naked)
    end
    check.call("explicit Gem.use_gemdeps #{path}", [RbConfig.ruby, '-e', "Gem.use_gemdeps; #{gemdeps}"], '', extra, true, :active)
  end
  check.call('explicit Gem.use_gemdeps argument', [RbConfig.ruby, '-e', "Gem.use_gemdeps(#{File.join(app, 'Gemfile').inspect}); #{gemdeps}"], '', {}, true, :active)
  cwd = File.join(dir, 'unbundled')
  FileUtils.mkdir_p(cwd)
  check.call('unbundled explicit setup', [RbConfig.ruby, '-e', "require 'bundler'; begin; Bundler.setup; rescue Bundler::GemfileNotFound; end; #{probe}"], '', {}, true, :unbundled)
  exit 1 unless failures.empty?
end
