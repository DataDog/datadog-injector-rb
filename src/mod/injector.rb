# ruby-version-min: 1.8.7

LOG = import 'log'
CONTEXT = import 'context'
BUNDLER = import 'bundler'
RUBY = import 'ruby'

module Patch
  module Injector
    # - https://github.com/rubygems/rubygems/blob/v3.3.26/bundler/lib/bundler/injector.rb#L25
    # - https://github.com/rubygems/rubygems/blob/v3.5.6/bundler/lib/bundler/injector.rb#L25
    # - https://github.com/rubygems/rubygems/blob/v3.6.9/bundler/lib/bundler/injector.rb#L25
    def inject(gemfile_path, lockfile_path)
      # TODO: Bundler.definition is side-effectful
      # TODO: also it does not uses gempfile_path: report upstream?
      # Bundler.definition.ensure_equivalent_gemfile_and_lockfile(true)

      Bundler.settings.temporary(:deployment => false, :frozen => false) do
        builder = Bundler::Dsl.new
        builder.eval_gemfile(gemfile_path)

        # TODO: this should
        # - build list of app deps:
        #   `original_definition = builder.to_definition(lockfile_path, {})`
        # - for each new gem dep, if in active app gems then remove dep by name:
        #   `original_definition.specs.find { |s| s.name == 'ffi' }`
        # - else if in inactive deps => abort?:
        #   `original_definition.current_dependencies.find { |dep| dep.name == 'ffi'}`
        # - else keep it
        @deps.reject! { |d| builder.dependencies.any? { |dep| dep.name == d.name } }

        # aborts if gem added twice
        builder.eval_gemfile(Bundler::Injector::INJECTED_GEMS, build_gem_lines(false)) if @deps.any?

        @definition = builder.to_definition(lockfile_path, {})

        # aborts when gems are incompatible
        # e.g Bundler::SolveFailure (but only for bundler >2.4.0)
        @definition.resolve_remotely!

        # TODO: ideally, resolve only locally to avoid hitting rubygems
        # @definition.resolve_prefering_local!
        # @definition.resolve_only_locally!

        append_to(gemfile_path, build_gem_lines(@options[:conservative_versioning])) if @deps.any?

        if Gem::Requirement.new('< 2.5.6').satisfied_by? Gem::Version.new(Bundler::VERSION)
          @definition.lock(lockfile_path)
        else
          @definition.lock
        end

        Bundler.reset_paths!

        @deps
      end
    end
  end
end

class << self
  def call(context)
    LOG.info { "injector:call context:#{context}" }

    # TODO: check if nested injection (maybe very early too)
    # TODO: check if injection already performed

    package_gem_home = context[:inject][:ruby][:package][:gem_home]
    package_lockfile = context[:inject][:ruby][:package][:lockfile]

    # TODO: capture stdout+stderr
    gemfile, err = CONTEXT.isolate do
      Gem.paths = { 'GEM_PATH' => "#{package_gem_home}:#{ENV['GEM_PATH']}" }

      BUNDLER.send(:require!)

      # pinpoint app gemfile and lockfile
      app_gemfile  = context[:bundler][:gemfile]
      app_lockfile = context[:bundler][:lockfile]

      # determine output paths
      out = context[:fs][:target]

      # TODO: hash path + content to detect changes
      datadog_gemfile  = File.join(out, 'datadog.gemfile')
      datadog_lockfile = File.join(out, 'datadog.gemfile.lock')

      # TODO: this could be gathered in context
      # list gems packaged for injection
      package_locked = Bundler::LockfileParser.new(Bundler.read_file(package_lockfile))

      File.write(datadog_gemfile, File.read(app_gemfile))
      File.write(datadog_lockfile, File.read(app_lockfile))

      gems = package_locked.specs.map { |spec| Bundler::Dependency.new(spec.name, spec.version.to_s, options_for(spec.name)) }.uniq

      # TODO: this implementation hits sources to build a stable and consistent dependency graph but we only want to ever use local gems
      injector = Bundler::Injector.new(gems)
      injector.singleton_class.prepend(Patch::Injector)

      begin
        injector.inject(Pathname.new(datadog_gemfile), Pathname.new(datadog_lockfile))

        [datadog_gemfile, nil]
      rescue # TODO: improve error reporting accuracy
        [nil, "bundler.inject"]
      end
    end

    ENV['DD_INTERNAL_RUBY_INJECTOR'] = 'false'

    if err
      LOG.debug { "error: #{err}"}
      return [nil, err]
    end

    return [false, nil] unless gemfile

    if context[:bundler][:deployment]
      app_bundle_path = context[:bundler][:bundle_path]

      ENV['DD_INTERNAL_RUBY_INJECTOR_PATCH'] = "mode=deployment,path=#{package_gem_home}:#{app_bundle_path}"
      Gem.paths = { 'GEM_PATH' => "#{package_gem_home}:#{app_bundle_path}" }
      ENV['GEM_PATH'] = Gem.path.join(File::PATH_SEPARATOR)
      ENV['GEM_HOME'] = app_bundle_path

      BUNDLER.patch!
    else
      Gem.paths = { 'GEM_PATH' => "#{package_gem_home}:#{ENV['GEM_PATH']}" }
      ENV['GEM_PATH'] = Gem.path.join(File::PATH_SEPARATOR)
    end

    ENV['BUNDLE_GEMFILE'] = gemfile

    [true, nil]
  end

  def options_for(name)
    name == 'datadog' ? { 'require' => 'datadog/single_step_instrument' } : {}
  end
end
