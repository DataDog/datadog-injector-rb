# ruby-version-min: 1.8.7

LOG = import 'log'
CONTEXT = import 'context'
BUNDLER = import 'bundler'
DIRECT = import 'direct'
FORWARD_COMPATIBILITY = import 'forward_compatibility'

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
          complete_lockfile_checksums!

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

    def complete_lockfile_checksums!
      return unless @options[:complete_checksums]
      return unless @definition.respond_to?(:locked_checksums)
      return unless @definition.locked_checksums

      resolved_specs = @definition.resolve

      resolved_specs.each do |spec|
        store = spec.source.respond_to?(:checksum_store) && spec.source.checksum_store
        next unless store && (store.missing?(spec) || store.empty?(spec))

        cache_file = File.join(@options[:package_gem_home], 'cache', "#{spec.full_name}.gem")
        next unless File.file?(cache_file)

        require 'rubygems/package'
        checksum = Bundler::Checksum.from_gem_package(Gem::Package.new(cache_file))
        store.register(spec, checksum)
      end

      incomplete = resolved_specs.find do |spec|
        store = spec.source.respond_to?(:checksum_store) && spec.source.checksum_store
        store && (store.missing?(spec) || store.empty?(spec))
      end

      if incomplete
        raise LockfileWriteError.new("No checksum is available for #{incomplete.full_name}")
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

    return call_requested_direct(context) if context[:inject][:ruby][:direct]
    if context[:inject][:ruby][:direct_fallback] && FORWARD_COMPATIBILITY.required?(context)
      return call_direct_fallback(context, nil, 'forward.compatibility')
    end
    if context[:inject][:ruby][:direct_fallback] && !context[:fs][:writable]
      return call_direct_fallback(context, nil, 'fs.readonly')
    end

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
      injector = Bundler::Injector.new(
        gems,
        :complete_checksums => context[:bundler][:frozen],
        :package_gem_home => package_gem_home
      )
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

    if err
      LOG.debug { "injector:error code:#{err} msg:#{msg.inspect} cause:#{cause.inspect}"}

      if context[:inject][:ruby][:direct_fallback] && recoverable_for_direct?(err)
        return call_direct_fallback(context, err, err)
      end

      ENV['DD_INTERNAL_RUBY_INJECTOR'] = 'false'
      return [nil, err]
    end

    ENV['DD_INTERNAL_RUBY_INJECTOR'] = 'false'

    return [false, nil] unless gemfile

    # Detect vendored or deployment mode.
    #
    # Vendored mode: BUNDLE_PATH is set (via env, .bundle/config, etc.),
    # causing Bundler to install and load gems from that specific directory
    # rather than the system gem path. This is the general case.
    #
    # Deployment mode: BUNDLE_DEPLOYMENT is set, which implies vendored mode
    # (Bundler defaults BUNDLE_PATH to "vendor/bundle") and additionally
    # freezes the Gemfile and lockfile.
    #
    # Vendored is checked last so it takes precedence: when both are set,
    # the explicit BUNDLE_PATH matters more than the deployment default.
    mode = :deployment if context[:bundler][:deployment]
    mode = :vendored if context[:bundler][:settings][:path]

    # In vendored or deployment mode, Bundler restricts gem loading to the
    # bundle path. The injected gems live in the package gem home, not in
    # the app's bundle path, so we must:
    #
    # 1. Set GEM_PATH to include both the package gem home (where injected
    #    gems are installed) and the app's bundle path (where app gems are
    #    installed), so RubyGems can find gems from both locations.
    #
    # 2. Set GEM_HOME to the app's bundle path so that any gem installation
    #    goes to the expected location.
    #
    # 3. Patch Bundler settings (via BUNDLER.patch!) to neutralize the
    #    deployment flag and the path setting, preventing Bundler from
    #    complaining about gemfile/lockfile changes or restricting gem
    #    activation to only the bundle path. See bundler.rb patch! for
    #    details on what gets patched.
    #
    # 4. Persist the mode and paths in DD_INTERNAL_RUBY_INJECTOR_PATCH so
    #    that child processes (e.g. via `bundle exec`) can re-apply the
    #    patch. See main.rb's re-entry path.
    if mode == :deployment || mode == :vendored
      app_bundle_path = context[:bundler][:bundle_path]

      ENV['DD_INTERNAL_RUBY_INJECTOR_PATCH'] = "mode=#{mode},path=#{package_gem_home}:#{app_bundle_path}"

      # Reset RubyGems' in-memory path state so gems from both locations are
      # discoverable in the current process. Gem.paths= calls clear_paths and
      # builds a new PathSupport from ENV.to_hash merged with the given hash.
      # PathSupport#split_gem_path splits GEM_PATH, appends GEM_HOME, and
      # deduplicates. Note: Gem.paths= does NOT modify ENV — it only sets
      # the in-memory @paths and updates Gem::Specification.dirs.
      Gem.paths = { 'GEM_PATH' => "#{package_gem_home}:#{app_bundle_path}" }

      # Persist the fully resolved Gem.path to ENV for child processes.
      # Gem.path may include additional entries beyond what we explicitly set
      # (e.g. the current GEM_HOME appended by PathSupport), so we read it
      # back rather than recomputing it.
      ENV['GEM_PATH'] = Gem.path.join(File::PATH_SEPARATOR)

      # Set GEM_HOME in ENV for child processes. This does not reset @paths
      # or Gem.dir in the current process, but child processes (and any
      # future Gem.paths reset) will resolve GEM_HOME to the app's bundle
      # path, where app gems are installed.
      ENV['GEM_HOME'] = app_bundle_path

      BUNDLER.patch!
    else
      # Non-vendored mode: Bundler uses system gems (no BUNDLE_PATH set),
      # so we only need to prepend the package gem home to the existing
      # GEM_PATH. No GEM_HOME override is needed (system default is fine),
      # and no Bundler settings patch is needed since there are no
      # deployment/path restrictions to neutralize.
      Gem.paths = { 'GEM_PATH' => "#{package_gem_home}:#{ENV['GEM_PATH']}" }
      ENV['GEM_PATH'] = Gem.path.join(File::PATH_SEPARATOR)
    end

    ENV['BUNDLE_GEMFILE'] = gemfile

    [true, nil]
  end

  def call_direct(context)
    begin
      [DIRECT.call(context), nil]
    rescue DIRECT::SetupError => e
      LOG.debug { "injector:error code:bundler.direct.setup msg:#{e.message.inspect} cause:#{e.cause.inspect}" }
      [nil, 'bundler.direct.setup']
    rescue DIRECT::ResolutionError => e
      LOG.debug { "injector:error code:bundler.direct.resolve msg:#{e.message.inspect} cause:#{e.cause.inspect}" }
      [nil, 'bundler.direct.resolve']
    rescue DIRECT::LoadError => e
      LOG.debug { "injector:error code:bundler.direct.load msg:#{e.message.inspect} cause:#{e.cause.inspect}" }
      [nil, 'bundler.direct.load']
    end
  end

  def call_requested_direct(context)
    original_err = ENV['DD_INTERNAL_RUBY_INJECTOR_DIRECT_FALLBACK_ERROR']
    injected, direct_err = call_direct(context)

    # A bundle/bundler CLI defers direct loading to its application child.
    # Keep the fallback context in the environment until that child resolves.
    return [injected, direct_err] if injected == false && !direct_err

    ENV.delete('DD_INTERNAL_RUBY_INJECTOR_DIRECT_FALLBACK_ERROR')

    if direct_err && original_err
      ENV.delete('DD_INTERNAL_RUBY_INJECTOR_DIRECT')
      ENV['DD_INTERNAL_RUBY_INJECTOR'] = 'false'
      return [nil, original_err]
    end

    [injected, direct_err]
  end

  def call_direct_fallback(context, original_err, trigger)
    previous_direct = ENV['DD_INTERNAL_RUBY_INJECTOR_DIRECT']
    previous_fallback_error = ENV['DD_INTERNAL_RUBY_INJECTOR_DIRECT_FALLBACK_ERROR']
    ENV['DD_INTERNAL_RUBY_INJECTOR_DIRECT'] = 'true'
    ENV['DD_INTERNAL_RUBY_INJECTOR_DIRECT_FALLBACK_ERROR'] = original_err if original_err

    LOG.info { "injector:direct_fallback trigger:#{trigger}" }

    begin
      injected, direct_err = call_direct(context)
    rescue StandardError
      restore_direct_environment(previous_direct, previous_fallback_error)
      raise
    end

    unless direct_err
      ENV.delete('DD_INTERNAL_RUBY_INJECTOR_DIRECT_FALLBACK_ERROR') unless injected == false
      return [injected, nil]
    end

    restore_direct_environment(previous_direct, previous_fallback_error)
    ENV['DD_INTERNAL_RUBY_INJECTOR'] = 'false' if original_err

    LOG.debug { "injector:direct_fallback failed trigger:#{trigger} err:#{direct_err}" }
    [nil, original_err || direct_err]
  end

  def restore_direct_environment(previous_direct, previous_fallback_error)
    if previous_direct
      ENV['DD_INTERNAL_RUBY_INJECTOR_DIRECT'] = previous_direct
    else
      ENV.delete('DD_INTERNAL_RUBY_INJECTOR_DIRECT')
    end

    if previous_fallback_error
      ENV['DD_INTERNAL_RUBY_INJECTOR_DIRECT_FALLBACK_ERROR'] = previous_fallback_error
    else
      ENV.delete('DD_INTERNAL_RUBY_INJECTOR_DIRECT_FALLBACK_ERROR')
    end
  end

  def recoverable_for_direct?(err)
    return true if err == 'fs.write'
    return true if err == 'bundler.inject'

    !!(err =~ %r{\Abundler\.inject\.(?:resolve|gemfile\.(?:eval|inject|write)|lockfile\.write)\z})
  end

  def options_for(name)
    name == 'datadog' ? { 'require' => 'datadog/single_step_instrument' } : {}
  end
end
