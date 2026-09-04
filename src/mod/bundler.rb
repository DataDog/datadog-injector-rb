# ruby-version-min: 1.8.7

MEMFD = import 'memfd'

class << self
  def status
    require!
    configure_gemdeps!

    {
      :rubygems                => Gem::VERSION,
      :gem_path                => Gem.path,
      :version                 => Bundler::VERSION,
      :simulate_version        => Bundler.settings[:simulate_version],
      :gemfile                 => (Bundler.default_gemfile rescue nil),
      :lockfile                => (Bundler.default_lockfile rescue nil),
      :bundled                 => Bundler::SharedHelpers.in_bundle?,
      :locked                  => (Bundler.default_lockfile.exist? rescue nil),
      :frozen                  => Bundler.frozen_bundle?,
      :deployment              => Bundler.settings[:deployment],
      :root                    => (Bundler.root rescue nil),
      :bundle_path             => (Bundler.bundle_path rescue nil),
      :use_system_gems         => (Bundler.settings.path.use_system_gems? rescue nil),
      :home                    => (Bundler.home rescue nil),
      :install_path            => (Bundler.install_path rescue nil),
      :app_config_path         => (Bundler.app_config_path rescue nil),
      :settings => {
        :gem_home                => ENV['GEM_HOME'],
        :gem_path                => ENV['GEM_PATH'],
        :gemfile                 => Bundler.settings[:gemfile],
        :deployment              => Bundler.settings[:deployment],
        :frozen                  => Bundler.settings[:frozen],
        :path                    => Bundler.settings[:path],
        :app_config              => Bundler.settings[:app_config],
        :force_ruby_platform     => Bundler.settings[:force_ruby_platform],
      },
    }
  end

  def patch!(payload)
    require!

    # Patch Bundler::Settings to neutralize deployment and vendored mode
    # restrictions so that Bundler doesn't complain about gemfile/lockfile
    # changes made by the injector or restrict gem activation.
    #
    # Two things need patching:
    #
    # 1. Settings#[] — intercepted for :deployment and :path.
    #
    #    :deployment (BOOL_KEYS) is returned as false so Bundler doesn't
    #    enforce frozen gemfile/lockfile checks at runtime.
    #
    #    :path (STRING_KEYS) is returned as nil so any direct readers
    #    (e.g. Bundler.settings[:path]) see no explicit path configured.
    #    However, Settings#[] alone is NOT sufficient for :path because
    #    Settings#path (the method) reads from config hashes directly via
    #    value_for(), bypassing #[]. That's why we also need (2).
    #
    # 2. Settings#path (the method) — overridden to return Path.new(nil, true).
    #
    #    Bundler.bundle_path is derived from settings.path via
    #    Bundler.configured_bundle_path. The original Settings#path iterates
    #    over config levels (temporary, local, env, global) using value_for()
    #    to find the "path" setting, and falls back to "vendor/bundle" when
    #    deployment mode is on:
    #
    #    - https://github.com/ruby/rubygems/blob/v3.6.2/bundler/lib/bundler/settings.rb#L252-L265
    #
    #    By returning Path.new(nil, true) (no explicit_path, system_path=true),
    #    Path#use_system_gems? returns true, and Path#base_path falls through
    #    to Bundler.rubygems.gem_dir (i.e. Gem.dir), which is governed by
    #    GEM_HOME/GEM_PATH that we've already set up in injector.rb to include
    #    both the package gem home and the app's bundle path.
    unless @settings_patched
      mod = Module.new do
        def [](name)
          return false if name == :deployment
          return nil if name == :path

          super
        end

        def path
          ::Bundler::Settings::Path.new(nil, true)
        end
      end

      ::Bundler::Settings.prepend mod
      @settings_patched = true
    end

    patch_exec!
    patch_reads!(payload)
  end

  def patch_frozen!
    return if @frozen_patched

    mod = Module.new do
      def [](name)
        return false if name == :frozen

        super
      end
    end

    ::Bundler::Settings.prepend mod
    @frozen_patched = true
  end

  def patch_exec!
    return if @exec_patched

    require!
    require 'bundler/cli'
    require 'bundler/cli/exec'

    patcher = self
    mod = Module.new do
      define_method(:kernel_exec) do |*args|
        patcher.prepare_child_environment!
        MEMFD.preserve_exec!(args)

        super(*args)
      end
    end

    ::Bundler::CLI::Exec.prepend mod
    @exec_patched = true
  end

  def patch_environment!
    return if @environment_patched

    patcher = self
    mod = Module.new do
      define_method(:set_bundle_environment) do
        result = super()
        patcher.prepare_child_environment!
        result
      end
    end

    ::Bundler::SharedHelpers.singleton_class.prepend(mod)
    @environment_patched = true
  end

  def patch_unbundled!
    return if @unbundled_patched

    mod = Module.new do
      def unbundled_env
        super.tap do |env|
          env['DD_INTERNAL_RUBY_INJECTOR'] = 'false'
          env.delete('DD_INTERNAL_RUBY_INJECTOR_BUNDLE')
          env.delete('DD_INTERNAL_RUBY_INJECTOR_MEMFD')
          env.delete('DD_INTERNAL_RUBY_INJECTOR_PATCH')
        end
      end

      def unbundled_system(*args)
        MEMFD.close_exec!(args)
        super(*args)
      end

      def unbundled_exec(*args)
        MEMFD.close_exec!(args)
        super(*args)
      end
    end

    ::Bundler.singleton_class.prepend(mod)
    @unbundled_patched = true
  end

  def prepare_child_environment!
    rubyopt = ENV['RUBYOPT']
    return unless rubyopt

    injector_pattern = %r{(?:\A|\s)(-r\s*\S*/(?:injector|host_inject|auto_inject)\.rb)(?=\s|\z)}
    injector_match = rubyopt.match(injector_pattern)
    return unless injector_match

    injector = injector_match[1]
    rest = rubyopt.sub(injector_match[0], ' ').strip
    ENV['RUBYOPT'] = rest.empty? ? injector : "#{injector} #{rest}"
    ENV.delete('BUNDLER_SETUP')
  end

  def patch_reads!(payload)
    require!
    @read_payload = payload
    patch_frozen!
    patch_environment!
    patch_unbundled!
    patch_runtime_lock!

    return if @reads_patched

    patcher = self
    mod = Module.new do
      define_method(:read_file) do |file|
        content = patcher.virtual_file(file)
        content ? content.dup : super(file)
      end
    end

    ::Bundler.singleton_class.prepend(mod)
    @reads_patched = true
  end

  def patch_runtime_lock!
    return if @runtime_lock_patched

    patcher = self
    mod = Module.new do
      define_method(:lock) do |*args|
        patcher.virtual_lockfile?(@definition) ? nil : super(*args)
      end
    end

    ::Bundler::Runtime.prepend(mod)
    @runtime_lock_patched = true
  end

  def virtual_file(file)
    return unless @read_payload

    path = File.expand_path(file.to_s)
    case path
    when @read_payload[:gemfile_path]
      @read_payload[:gemfile_content]
    when @read_payload[:lockfile_path]
      @read_payload[:lockfile_content]
    end
  end

  def virtual_lockfile?(definition)
    return false unless @read_payload

    lockfile = definition.instance_variable_get(:@lockfile)
    lockfile && File.expand_path(lockfile.to_s) == @read_payload[:lockfile_path]
  end

  private

  def configure_gemdeps!
    return if ENV['BUNDLE_GEMFILE']

    path = ENV['RUBYGEMS_GEMDEPS']
    return if !path || path.empty?

    path = discover_gemdeps if path == '-'
    ENV['BUNDLE_GEMFILE'] = File.expand_path(path) if path && File.file?(path)
  end

  def discover_gemdeps
    directory = File.expand_path(Dir.pwd)
    names = defined?(Gem::GEM_DEP_FILES) ? Gem::GEM_DEP_FILES : %w[gem.deps.rb gems.rb Gemfile Isolate]

    loop do
      names.each do |name|
        path = File.join(directory, name)
        return path if File.file?(path)
      end

      parent = File.expand_path('..', directory)
      return if parent == directory
      directory = parent
    end
  end

  def require!
    # require rubygems first, otherwise there may be a per-file mixup between
    # bundler versions (observed: stdlib vs gem home)
    require 'rubygems'

    require 'bundler'
  end
end
