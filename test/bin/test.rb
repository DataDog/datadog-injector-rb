INJECTION_DIR = File.expand_path(File.join(__dir__, '..', '..'))

# Idealised syntax
#
# fixture:unbundled
#   for ruby:1.8..3.4 jruby:9.2..9.4
#     telemetry should include start
#     injection should abort
#     abort reason should include bundler.unbundled
#
# for fixture:deployment fixture:hot,env:BUNDLER_DEPLOYMENT=true
#   for ruby:1.8..3.4 jruby:9.2..9.4
#     telemetry should include start
#     injection should abort
#     abort reason should include bundler.deployment
#
# for fixture:frozen fixture:hot,env:BUNDLER_FROZEN=true
#   for ruby:1.8..3.4 jruby:9.2..9.4
#     telemetry should include start
#     injection should abort
#     abort reason should include bundler.frozen
#
# fixture:[hot,deployment,frozen],bundle:unlocked
#   for ruby:1.8..3.4 jruby:9.2..9.4
#     telemetry should include start
#     injection should abort
#     abort reason should include bundler.unlocked
#
# for fixture:hot fixture:unbundled,env:BUNDLE_GEMFILE=../hot/Gemfile
#   for ruby:1.8..2.3
#     telemetry should include start
#     telemetry should include runtime.parser
#
#   for ruby:1.8..2.5
#     telemetry should include start
#     telemetry should include runtime.version
#
#   for jruby:9.2..9.4
#     telemetry should include start
#     telemetry should include runtime.engine
#     telemetry should include runtime.forkless
#
#   for ruby:2.6..3.4
#     injection should start
#       telemetry should include start
#     injection should proceed
#       telemetry should include start
#     injection should succeed
#       telemetry should include complete

SUITE = [
  [
    { fixture: 'hot', bundle: 'unlocked' },
    { fixture: 'deployment', bundle: 'unlocked' },
    { fixture: 'frozen', bundle: 'unlocked' },
    { fixture: 'unbundled' },
  ] => {
    [
      { engine: 'ruby', version: '1.8' },
      { engine: 'ruby', version: '1.9' },
      { engine: 'ruby', version: '2.0' },
      { engine: 'ruby', version: '2.1' },
      { engine: 'ruby', version: '2.2' },
      { engine: 'ruby', version: '2.3' },
      { engine: 'ruby', version: '2.4' },
      { engine: 'ruby', version: '2.5' },
      { engine: 'ruby', version: '2.6' },
      { engine: 'ruby', version: '2.7' },
      { engine: 'ruby', version: '3.0' },
      { engine: 'ruby', version: '3.1' },
      { engine: 'ruby', version: '3.2' },
      { engine: 'ruby', version: '3.3' },
      { engine: 'ruby', version: '3.4' },
      { engine: 'jruby', version: '9.2' },
      { engine: 'jruby', version: '9.3' },
      { engine: 'jruby', version: '9.4' },
    ] => [
      'telemetry should include start',
      'injection should abort',
      'abort reason should include bundler.unlocked',
    ],
  },

  { fixture: 'unbundled' } => {
    [
      { engine: 'ruby', version: '1.8' },
      { engine: 'ruby', version: '1.9' },
      { engine: 'ruby', version: '2.0' },
      { engine: 'ruby', version: '2.1' },
      { engine: 'ruby', version: '2.2' },
      { engine: 'ruby', version: '2.3' },
      { engine: 'ruby', version: '2.4' },
      { engine: 'ruby', version: '2.5' },
      { engine: 'ruby', version: '2.6' },
      { engine: 'ruby', version: '2.7' },
      { engine: 'ruby', version: '3.0' },
      { engine: 'ruby', version: '3.1' },
      { engine: 'ruby', version: '3.2' },
      { engine: 'ruby', version: '3.3' },
      { engine: 'ruby', version: '3.4' },
      { engine: 'jruby', version: '9.2' },
      { engine: 'jruby', version: '9.3' },
      { engine: 'jruby', version: '9.4' },
    ] => [
      'telemetry should include start',
      'injection should abort',
      'abort reason should include bundler.unbundled',
    ],
  },

  { bundle: 'locked' } => [
    [{ fixture: 'deployment' }, { fixture: 'hot', env: 'BUNDLE_DEPLOYMENT=true' }] => {
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
        { engine: 'ruby', version: '2.4' },
        { engine: 'ruby', version: '2.5' },
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'jruby', version: '9.2' },
        { engine: 'jruby', version: '9.3' },
        { engine: 'jruby', version: '9.4' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include bundler.deployment',
      ],
    },
    [{ fixture: 'frozen' }, { fixture: 'hot', env: 'BUNDLE_FROZEN=true' }] => {
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
        { engine: 'ruby', version: '2.4' },
        { engine: 'ruby', version: '2.5' },
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'jruby', version: '9.2' },
        { engine: 'jruby', version: '9.3' },
        { engine: 'jruby', version: '9.4' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include bundler.frozen',
      ],
    },
    { fixture: 'hot', env: 'BUNDLE_PATH=/bundle' } => {
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.parser',
      ],
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
        { engine: 'ruby', version: '2.4' },
        { engine: 'ruby', version: '2.5' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.version',
      ],
      [
        { engine: 'jruby', version: '9.2' },
        { engine: 'jruby', version: '9.3' },
        { engine: 'jruby', version: '9.4' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.engine',
        'abort reason should include runtime.forkless',
      ],
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include bundler.vendored',
      ],
    },
    { fixture: 'hot' } => {
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.parser',
      ],
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
        { engine: 'ruby', version: '2.4' },
        { engine: 'ruby', version: '2.5' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.version',
      ],
      [
        { engine: 'jruby', version: '9.2' },
        { engine: 'jruby', version: '9.3' },
        { engine: 'jruby', version: '9.4' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.engine',
        'abort reason should include runtime.forkless',
      ],
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
      ] => [
        'telemetry should include start',
        'injection should proceed',
        'injection should succeed',
        'telemetry should include complete',
        'abort reason should be empty',
      ],
    },
    { fixture: 'hot', inject: true, injector: 'datadog', packaged: true } => {
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
      ] => [
        'telemetry should include complete',
        'app gemfile should not include datadog',
        'app lockfile should not include datadog',
        'new gemfile should include datadog',
        'new lockfile should include datadog',
        'gem datadog should have require option',
      ],
    }
  ]
]

def flatten(val, ele=nil, acc=nil)
  ele ||= {}
  acc ||= []

  case val
  when String, Symbol
    acc << ele.merge(:test => val)
  when Array
    val.each { |v| flatten(v, ele, acc) }
  when Hash
    val.each do |k, v|
      case k
      when Symbol, String
        flatten(v, ele.merge(k => true), acc)
      when Array
        k.each { |kv| flatten(v, ele.merge(kv), acc) }
      when Hash
        flatten(v, ele.merge(k), acc)
      end
    end
  end

  acc
end

EXAMPLES = {}

def example(desc, &block)
  EXAMPLES[desc] = block
end

example 'telemetry should include start' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.start' } }
end

example 'injection should abort' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' } }
end

example 'abort reason should include runtime.version' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.version') } }
end

example 'abort reason should include runtime.parser' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.parser') } }
end

example 'abort reason should include bundler.deployment' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.deployment') } }
end

example 'abort reason should include bundler.frozen' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.frozen') } }
end

example 'abort reason should include bundler.unbundled' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.unbundled') } }
end

example 'abort reason should include bundler.unlocked' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.unlocked') } }
end

example 'abort reason should include bundler.vendored' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.vendored') } }
end

example 'abort reason should include runtime.engine' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.engine') } }
end

example 'abort reason should include runtime.forkless' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.forkless') } }
end

example 'injection should proceed' do |context|
  # TODO: do it with logs?
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.proceed' } }
end

example 'injection should succeed' do |context|
  # TODO: do it with logs?
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.succeed' } }
end

example 'telemetry should include complete' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.complete' } }
end

example 'abort reason should be empty' do |context|
  context.telemetry.all? { |e| e['points'].all? { |p| p['name'] != 'library_entrypoint.abort' } }
end

example 'app gemfile should not include datadog' do |context|
  gemfile = File.join(context.path, 'Gemfile')
  !File.read(gemfile).include?('gem "datadog"')
end

example 'app lockfile should not include datadog' do |context|
  lockfile = File.join(context.path, 'Gemfile.lock')
  !File.read(lockfile).include?(' datadog ')
end

example 'new gemfile should include datadog' do |context|
  gemfile = File.join(context.path, 'datadog.gemfile')
  File.read(gemfile).include?('gem "datadog"')
end

example 'new lockfile should include datadog' do |context|
  lockfile = File.join(context.path, 'datadog.gemfile.lock')
  File.read(lockfile).include?(' datadog ')
end

example 'gem datadog should have require option' do |context|
  gemfile = File.join(context.path, 'datadog.gemfile')
  File.readlines(gemfile).grep(/gem "datadog"/).any?(%r{:require => "datadog/single_step_instrument"})
end

RUNTIMES = {
  'ruby' => {
    '1.8' => { tag: '1.8-centos', arch: ['x86_64'] },
    '1.9' => { tag: '1.9-centos', arch: ['x86_64'] },
    '2.0' => { tag: '2.0-centos', arch: ['x86_64'] },
    '2.1' => { tag: '2.1-centos', arch: ['x86_64'] },
    '2.2' => { tag: '2.2-centos', arch: ['aarch64', 'x86_64'] },
    '2.3' => { tag: '2.3-centos', arch: ['aarch64', 'x86_64'] },
    '2.4' => { tag: '2.4-centos', arch: ['aarch64', 'x86_64'] },
    '2.5' => { tag: '2.5-centos', arch: ['aarch64', 'x86_64'] },
    '2.6' => { tag: '2.6-centos', arch: ['aarch64', 'x86_64'] },
    '2.7' => { tag: '2.7-centos', arch: ['aarch64', 'x86_64'] },
    '3.0' => { tag: '3.0-centos', arch: ['aarch64', 'x86_64'] },
    '3.1' => { tag: '3.1-centos', arch: ['aarch64', 'x86_64'] },
    '3.2' => { tag: '3.2-centos', arch: ['aarch64', 'x86_64'] },
    '3.3' => { tag: '3.3-centos', arch: ['aarch64', 'x86_64'] },
    '3.4' => { tag: '3.4-centos', arch: ['aarch64', 'x86_64'] },
  },
  'jruby' => {
    '9.2' => { tag: '9.2-gnu', arch: ['aarch64', 'x86_64'] },
    '9.3' => { tag: '9.3-gnu', arch: ['aarch64', 'x86_64'] },
    '9.4' => { tag: '9.4-gnu', arch: ['aarch64', 'x86_64'] },
  }
}

# TODO: these are sane-ish defaults
PLATFORM_ARCH = {
  /^x86_64-linux/  => ['x86_64'],
  /^x86_64-darwin/ => ['x86_64'],
  /^aarch64-linux/ => ['aarch64'],
  /^arm64-darwin/  => ['aarch64', 'x86_64'],
}

def arches_for_platform
  PLATFORM_ARCH.find { |k, _| RUBY_PLATFORM =~ k }&.last
end

def resolve_arch(runtime_arches)
  arches_for_platform.find { |arch| runtime_arches.include?(arch) }
end

def run(*args, engine: nil, version: nil, arch: nil)
  env = args.first.is_a?(Hash) ? args.shift : {}

  runtime = RUNTIMES[engine][version] if engine && version

  cmd = []

  env = {
    'DD_TELEMETRY_FORWARDER_PATH' => "#{INJECTION_DIR}/test/bin/forwarder.rb",
    'BUNDLE_APP_CONFIG' => "#{Dir.pwd}/.bundle",
  }.merge(env)

  if runtime
    tag = runtime[:tag]
    arch ||= resolve_arch(runtime[:arch])

    # TODO: what if arch is still nil now

    cmd += %W[
      docker run --rm
    ]

    cmd += %W[
      --interactive --tty
    ] if $stdout.isatty

    cmd += %W[
      --volume #{INJECTION_DIR}:#{INJECTION_DIR}:rw
      --volume datadog-injector-rb-bundle-shared-#{engine}-#{tag}-#{arch}:/usr/local/bundle:rw
      --volume datadog-injector-rb-bundle-deployment-#{engine}-#{tag}-#{arch}:#{Dir.pwd}/vendor/bundle:rw
      --volume #{Dir.pwd}:#{Dir.pwd}:rw
      --workdir #{Dir.pwd}
      --platform linux/#{arch}
    ]

    cmd += env.keys.map { |e| %W[ --env #{e} ] }.flatten

    cmd += %W[
      ghcr.io/datadog/images-rb/engines/#{engine}:#{tag}
    ]
  end

  cmd += args

# spawn(env, *cmd, [:out, :err] => '/dev/null')
  spawn(env, *cmd)
end

class Context
  attr_reader :telemetry, :path

  def initialize(telemetry: telemetry, path: path)
    @telemetry = telemetry
    @path = path
  end
end

def main(argv)
  keep = false # TODO: handle from command line

  err = []
  miss = []
  fail = []

  matrix = flatten(SUITE)

  # TODO: matrix should be NOOP-explorable from the command line
  # pp matrix
  # p matrix.count
  # p matrix.uniq.count
  # pp matrix.group_by { |e| [e[:engine], e[:version]] }

  rows = matrix.uniq

# TODO: these should be possible to filter straight from the command line
# rows = matrix.select { |e| e[:engine] == 'ruby' && e[:version] == '1.8' && ['hot', 'deployment', 'frozen'].include?(e[:fixture]) }
# rows = matrix.select { |e| e[:engine] == 'ruby' && e[:version] == '1.8' }
# rows = matrix.select { |e| e[:engine] == 'ruby' && e[:version] == '3.4' && e[:bundle] == 'locked' }
# rows = matrix.uniq.select { |row| row[:engine] == RUBY_ENGINE && row[:version] == (RUBY_VERSION =~ /^(\d+\.\d+)/ && $1) }
# rows = matrix.uniq.select { |row| row[:engine] == 'ruby' }
# rows = matrix.uniq.select { |row| row[:engine] == 'ruby' && row[:version] == '3.4' && row[:fixture] == 'hot' }
# rows = matrix.uniq.select { |row| row[:engine] == 'jruby' && row[:version] == '9.2' && row[:fixture] == 'hot' }
# rows = matrix.uniq.select { |row| row[:engine] == 'jruby' }
# rows = matrix.uniq.select { |row| row == {bundle: "locked", fixture: "deployment", engine: "jruby", version: "9.2", test: "injection should abort"} }

  require 'fileutils'
  require 'securerandom'
  require 'json'

  start = Time.now

  rows.each do |row|
    uuid = SecureRandom.uuid
    puts "=== run: #{row.inspect} uuid: #{uuid}"

    tmp = "#{INJECTION_DIR}/test/tmp/run/#{row[:fixture]}-#{uuid}"
    FileUtils.mkdir_p(tmp)
    begin
      fixture = row[:fixture]
      FileUtils.cp_r "test/fixtures/#{fixture}", tmp

      lock = row[:bundle] == 'locked'
      packaged = row[:packaged]

      if packaged
        package_basepath = "#{INJECTION_DIR}/test/packages/#{row[:injector]}"
        package_gem_home = "#{package_basepath}/#{row[:version]}.0"

        env = { 'BUNDLE_GEMFILE' => "#{package_gem_home}/Gemfile", 'GEM_HOME' => package_gem_home }
        pid = run env, *%W[ bundle install ], engine: row[:engine], version: row[:version]
        _pid, status = Process.waitpid2(pid)
        if status.exitstatus != 0
          puts "==> ERR"
          err << row
          next
        end
      end

      Dir.chdir tmp do
        Dir.chdir fixture do
          if lock
            # ignore fixture config, notably development/frozen which would prevent lock
            env = { 'BUNDLE_APP_CONFIG' => '/nowhere' }
            pid = run env, *%W[ bundle lock ], engine: row[:engine], version: row[:version]
            _pid, status = Process.waitpid2(pid)
            if status.exitstatus != 0
              puts "==> ERR"
              err << row
              next
            end

            pid = run *%W[ bundle install ], engine: row[:engine], version: row[:version]
            _pid, status = Process.waitpid2(pid)
            if status.exitstatus != 0
              puts "==> ERR"
              err << row
              next
            end
          end

          env = if (e = row[:env])
                  k, v = e.split('=', 2)
                  { k => v }
                else
                  {}
                end
          env = { 'DD_TELEMETRY_FORWARDER_LOG' => "#{tmp}/forwarder.log" }.merge(env)
          env['DD_INTERNAL_RUBY_INJECTOR'] = 'false' unless row[:inject]
          env['DD_INTERNAL_RUBY_INJECTOR_BASEPATH'] = "#{INJECTION_DIR}/test/packages/#{row[:injector]}"

          pid = run env, *%W[ ruby -r #{INJECTION_DIR}/src/injector.rb stub.rb ],
                    engine: row[:engine], version: row[:version]
          _pid, status = Process.waitpid2(pid)
          if status.exitstatus != 0
            puts "==> ERR"
            err << row
            next
          end

          if File.exist? "#{tmp}/forwarder.log"
            test = EXAMPLES[row[:test]]
            telemetry = File.open("#{tmp}/forwarder.log") { |f| f.each_line.map { |l| JSON.parse(l) } }

            context = Context.new(
              telemetry: telemetry,
              path: Dir.pwd,

              # TODO: add stdout+stderr
            )

            if test.nil?
              puts "==> MISS"
              miss << row[:test]
            elsif test.call(context)
              puts "==> OK"
            else
              puts "==> FAIL"
              fail << row
            end

          # FileUtils.mv "#{tmp}/forwarder.log", "#{INJECTION_DIR}/forwarder.log"
          end
        end
      end
    ensure
      FileUtils.rm_rf tmp unless keep
    end
  end

  delta = Time.now - start

  if fail.count > 0
    puts "\n!!! failed: #{fail.count}"
    fail.uniq.each do |f|
      puts "!!! -- #{f.inspect}"
    end
  end

  if err.count > 0
    puts "\n!!! errors: #{err.count}"
    err.uniq.each do |e|
      puts "!!! -- #{e.inspect}"
    end
  end

  if miss.count > 0
    puts "\n!!! missing: #{miss.uniq.count}"
    miss.uniq.each { |m| puts "!!! -- #{m}" }
  end

  puts "\n=== ran:#{rows.count} fail:#{fail.count} miss:#{miss.uniq.count} err:#{err.count} time:#{delta}"

  exit 1 if fail.count + miss.count + err.count > 0
end

main(ARGV) if $0 == __FILE__
