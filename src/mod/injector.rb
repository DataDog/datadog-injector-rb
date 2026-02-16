# ruby-version-min: 1.8.7

LOG = import 'log'
CONTEXT = import 'context'
BUNDLER = import 'bundler'

module Patch
  module Injector
    # Custom exceptions for granular error reporting
    class InjectionError < StandardError
      attr_reader :cause

      def initialize(message, cause = nil)
        super(message)

        @cause = cause
      end
    end

    class ResolutionError < InjectionError; end
    class GemfileWriteError < InjectionError; end
    class LockfileWriteError < InjectionError; end
    class GemfileEvalError < InjectionError; end
    class GemfileInjectError < InjectionError; end

    # - https://github.com/rubygems/rubygems/blob/v3.3.26/bundler/lib/bundler/injector.rb#L25
    # - https://github.com/rubygems/rubygems/blob/v3.5.6/bundler/lib/bundler/injector.rb#L25
    # - https://github.com/rubygems/rubygems/blob/v3.6.9/bundler/lib/bundler/injector.rb#L25
    def inject(gemfile_path, lockfile_path)
      # TODO: Bundler.definition is side-effectful
      # TODO: also it does not uses gempfile_path: report upstream?
      # Bundler.definition.ensure_equivalent_gemfile_and_lockfile(true)

      Bundler.settings.temporary(:deployment => false, :frozen => false) do
        builder = Bundler::Dsl.new

        # Gemfile original contents: read, parse, evaluate
        begin
          builder.eval_gemfile(gemfile_path)
        rescue StandardError => e
          raise GemfileEvalError.new("Failed to evaluate original gemfile contents", e)
        end

        # Filter out dependencies to inject based on presence in original Gemfile
        #
        # TODO: this should
        # - build list of app deps:
        #   `original_definition = builder.to_definition(lockfile_path, {})`
        # - for each new gem dep, if in active app gems then remove dep by name:
        #   `original_definition.specs.find { |s| s.name == 'ffi' }`
        # - else if in inactive deps => abort?:
        #   `original_definition.current_dependencies.find { |dep| dep.name == 'ffi'}`
        # - else keep it
        @deps.reject! { |d| builder.dependencies.any? { |dep| dep.name == d.name } }

        # Inject remaining dependencies into Gemfile
        #
        # Aborts if a gem is added twice.
        #
        # `INJECTED_GEMS` is a magic value:
        # - https://github.com/ruby/rubygems/blob/v3.6.9/bundler/lib/bundler/injector.rb#L5
        # - https://github.com/ruby/rubygems/blob/v3.6.9/bundler/lib/bundler/dsl.rb#L272
        #
        # `build_gem_lines` receives `false` to sidestep conservative
        # versioning, it'll be enforced later.
        begin
          builder.eval_gemfile(Bundler::Injector::INJECTED_GEMS, build_gem_lines(false)) if @deps.any?
        rescue StandardError => e
          raise GemfileInjectError.new("Failed to inject gems into original gemfile", e)
        end

        @definition = builder.to_definition(lockfile_path, {})

        # Perform resolution, ensuring either a valid dependency set or a bail-out
        #
        # This will use the exact current configuration, including groups and such.
        #
        # Aborts when gems are incompatible
        begin
          # TODO: resolve only locally once we're confident (negative condition
          # is a bit ugly but the whole condition is due to be removed)
          if ENV['DD_INTERNAL_RUBY_INJECTOR_RESOLUTION'] != 'remote'
            # SourceList#local_only! appears to exist consistently so far
            # - https://github.com/ruby/rubygems/blob/v3.4.0/bundler/lib/bundler/source_list.rb#L143
            # - https://github.com/ruby/rubygems/blob/v4.0.4/bundler/lib/bundler/source_list.rb#L121
            # Definition#sources went public on 3.5.23
            # - https://github.com/ruby/rubygems/commit/0d1252078053879ebc8a69abc243397af46f218a
            @definition.send(:sources).local_only!
            @definition.resolve
          else
            # Remote resolution with local preference saw many iterations:
            # - SourceList#prefer_local! appeared on 2.6.4, ultimately replacing Definition#prefer_local!
            #   https://github.com/ruby/rubygems/commit/209b93ad3679edb79585f831ac4b0046b045ce49
            #   https://github.com/ruby/rubygems/commit/3df86cd9c640655ec6ec85c1a2280621b56e7b77
            #   https://github.com/ruby/rubygems/commit/c034f30aa925748cda0967c13e31e25fa73bc5f1
            # - Definition#prefer_local! appeared on 2.5.11, dropping Definition#resolution_mode=
            #   https://github.com/ruby/rubygems/commit/639f0b72f40979b552b4bae44a122cfd176115aa
            #   https://github.com/ruby/rubygems/commit/bed579a49a554b8b205d2b0b5b1e85d356636c2c
            # - Definition#resolution_mode= appeared on 2.4.4, replacing Definition#resolve_prefering_local!
            #   https://github.com/ruby/rubygems/commit/47136c6b97c3385a4aea12f0eb0af1ba864f1924
            #   https://github.com/ruby/rubygems/commit/f8333a735d4c1226261db6d457261567f1021aaa
            # - Definition#resolve_prefering_local! appeared on 2.3.20
            #   https://github.com/ruby/rubygems/commit/f0d6d4c57e68b8d6db8c6b979db2866d419c59bd
            #   https://github.com/ruby/rubygems/commit/9bc5ebeb95204ecfb73e0f5a6181e37742563a4a
            if Gem::Requirement.new('< 2.4.4').satisfied_by? Gem::Version.new(Bundler::VERSION)
              @definition.resolve_prefering_local!
            elsif Gem::Requirement.new('< 2.5.11').satisfied_by? Gem::Version.new(Bundler::VERSION)
              @definition.resolution_mode = { 'prefer-local' => true }
              @definition.resolve_remotely!
            elsif Gem::Requirement.new('< 2.6.4').satisfied_by? Gem::Version.new(Bundler::VERSION)
              @definition.prefer_local!
              @definition.resolve_remotely!
            else
              @definition.send(:sources).prefer_local!
              @definition.resolve_remotely!
            end
          end
        rescue StandardError => e
          raise ResolutionError.new("Failed to resolve injected gemfile", e)
        end

        # Append injected gem lines to Gemfile on disk
        begin
          append_to(gemfile_path, build_gem_lines(@options[:conservative_versioning]))
        rescue StandardError => e
          raise GemfileWriteError.new("Failed to append to gemfile", e)
        end

        # Dump dependency resolution as a lockfile on disk
        begin
          # Definition#lock changed signature on 2.5.6
          # - https://github.com/ruby/rubygems/commit/2e282343a88db4373bbecead5ece293b5802526c
          # - https://github.com/ruby/rubygems/commit/7f801a3ff424ac6ac91f68ad988df5b78cebf99b
          if Gem::Requirement.new('< 2.5.6').satisfied_by? Gem::Version.new(Bundler::VERSION)
            @definition.lock(lockfile_path)
          else
            @definition.lock
          end
        rescue StandardError => e
          raise LockfileWriteError.new("Failed to write new lockfile", e)
        end

        # Invalidate Bundler.definition
        # TODO: may be unneeded since it is now uncalled in this implementation
        Bundler.reset_paths!

        # Return injected dependencies
        @deps
      end
    end
  end
end

class Err
  attr_reader :code, :message, :cause

  def initialize(code, e)
    @code = code
    @message = e.message
    @cause = e.respond_to?(:cause) ? "(#{e.cause.class}): #{e.cause.message}" : nil
  end

  def to_s
    @code
  end

  def inspect
    @cause ? "#{@code}: #{@message} [caused by: #{@cause}]" : "#{@code}: #{@message}"
  end

  def to_a
    [code, message, cause]
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
    gemfile, err, msg, cause = CONTEXT.isolate do
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

      begin
        File.write(datadog_gemfile, File.read(app_gemfile))
        File.write(datadog_lockfile, File.read(app_lockfile))
      rescue StandardError => e
        return [nil, *Err.new("fs.write", e).to_a]
      end

      gems = package_locked.specs.map { |spec| Bundler::Dependency.new(spec.name, spec.version.to_s, options_for(spec.name)) }.uniq

      # TODO: this implementation hits sources to build a stable and consistent dependency graph but we only want to ever use local gems
      injector = Bundler::Injector.new(gems)
      injector.singleton_class.prepend(Patch::Injector)

      begin
        injector.inject(Pathname.new(datadog_gemfile), Pathname.new(datadog_lockfile))

        [datadog_gemfile, nil]
      rescue Patch::Injector::GemfileEvalError => e
        [nil, *Err.new("bundler.inject.gemfile.eval", e).to_a]
      rescue Patch::Injector::GemfileInjectError => e
        [nil, *Err.new("bundler.inject.gemfile.inject", e).to_a]
      rescue Patch::Injector::ResolutionError => e
        [nil, *Err.new("bundler.inject.resolve", e).to_a]
      rescue Patch::Injector::GemfileWriteError => e
        [nil, *Err.new("bundler.inject.gemfile.write", e).to_a]
      rescue Patch::Injector::LockfileWriteError => e
        [nil, *Err.new("bundler.inject.lockfile.write", e).to_a]
      rescue Patch::Injector::InjectionError => e
        [nil, *Err.new("bundler.inject", e).to_a]
      rescue StandardError => e
        [nil, *Err.new("bundler.inject.unknown", e).to_a]
      end
    end

    ENV['DD_INTERNAL_RUBY_INJECTOR'] = 'false'

    if err
      LOG.debug { "injector:error code:#{err} msg:#{msg.inspect} cause:#{cause.inspect}"}
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
