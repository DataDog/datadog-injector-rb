# ruby-version-min: 1.8.7

LOG = import 'log'
CONTEXT = import 'context'
BUNDLER = import 'bundler'
RUBY = import 'ruby'

class << self
  def call
    LOG.info { 'injector:call' }

    # TODO: check if nested injection (maybe very early too)
    # TODO: check if injection already performed

    package_basepath = ENV['DD_INTERNAL_RUBY_INJECTOR_BASEPATH'] || File.expand_path(File.join(File.dirname(__FILE__), '..'))
    package_gem_home = ENV['DD_INTERNAL_RUBY_INJECTOR_GEM_HOME'] || File.join(package_basepath, RUBY.api_version)
    package_lockfile = ENV['DD_INTERNAL_RUBY_INJECTOR_LOCKFILE'] || File.join(package_gem_home, 'Gemfile.lock')

    # TODO: these are in context
    # pinpoint app gemfile and lockfile
    app_gemfile  = Bundler.default_gemfile
    app_lockfile = Bundler.default_lockfile

    # determine output paths
    # out = File.join(app_gemfile.dirname, 'tmp', 'datadog')
    out = File.join(app_gemfile.dirname)

    # TODO: hash path + content to detect changes
    datadog_gemfile  = File.join(out, 'datadog.gemfile')
    datadog_lockfile = File.join(out, 'datadog.gemfile.lock')

    success = CONTEXT.isolate do

      ENV['GEM_PATH'] = package_gem_home

      BUNDLER.send(:require!)

      # TODO: this could be gathered in context
      # list gems packaged for injection
      package_locked = Bundler::LockfileParser.new(Bundler.read_file(package_lockfile))

      File.write(datadog_gemfile, File.read(app_gemfile))
      File.write(datadog_lockfile, File.read(app_lockfile))

      gems = package_locked.specs.map { |spec| Bundler::Dependency.new(spec.name, spec.version.to_s, options_for(spec.name)) }.uniq

      # TODO: this implementation hits sources to build a stable and consistent dependency graph but we only want to ever use local gems
      injector = Bundler::Injector.new(gems)
      added = injector.inject(Pathname.new(datadog_gemfile), Pathname.new(datadog_lockfile))

      true
    end

    if success
      Gem.paths = { 'GEM_PATH' => "#{package_gem_home}:#{ENV['GEM_PATH']}" }
      ENV['GEM_PATH'] = Gem.path.join(File::PATH_SEPARATOR)
      ENV['BUNDLE_GEMFILE'] = datadog_gemfile
    end
  end

  def options_for(name)
    name == 'datadog' ? { 'require' => 'datadog/single_step_instrument' } : {}
  end
end
