# ruby-version-min: 1.8.7

class << self
  def status
    require!

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

  def patch!
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

    require 'bundler/cli'
    require 'bundler/cli/exec'

    mod = Module.new do
      def kernel_exec(*args)
        ENV['RUBYOPT'] = ENV['RUBYOPT'].gsub(%r{^(.*)(?:\s+|^)(-r(\s*)\S+/(?:injector|host_inject|auto_inject)\.rb)(.*)$}, '\2 \1 \3')
        ENV.delete('BUNDLER_SETUP')

        super
      end
    end

    ::Bundler::CLI::Exec.prepend mod

    # Install read interceptors so Bundler returns patched in-memory content
    # for the gemfile and lockfile instead of reading from disk.
    patch_reads!
  end

  # Patch Bundler.read_file to return in-memory gemfile and lockfile content.
  #
  # When DD_INTERNAL_RUBY_INJECTOR_GEMFILE_CONTENT and
  # DD_INTERNAL_RUBY_INJECTOR_LOCKFILE_CONTENT env vars are set, any call
  # to Bundler.read_file for the gemfile or lockfile path will return the
  # env var content instead of reading from disk. This allows the injector
  # to perform resolution without writing patched files to the filesystem.
  #
  # The gemfile and lockfile paths are derived from BUNDLE_GEMFILE (via
  # Bundler.default_gemfile / Bundler.default_lockfile), so BUNDLE_GEMFILE
  # must be set before calling this method.
  def patch_reads!
    gemfile_content  = ENV['DD_INTERNAL_RUBY_INJECTOR_GEMFILE_CONTENT']
    lockfile_content = ENV['DD_INTERNAL_RUBY_INJECTOR_LOCKFILE_CONTENT']

    return unless gemfile_content && lockfile_content

    require!

    gemfile_path  = ::Bundler.default_gemfile.to_s
    lockfile_path = ::Bundler.default_lockfile.to_s

    mod = Module.new do
      define_method(:read_file) do |file|
        case file.to_s
        when gemfile_path
          gemfile_content
        when lockfile_path
          lockfile_content
        else
          super(file)
        end
      end
    end

    ::Bundler.singleton_class.prepend(mod)
  end

  private

  def require!
    # require rubygems first, otherwise there may be a per-file mixup between
    # bundler versions (observed: stdlib vs gem home)
    require 'rubygems'

    require 'bundler'
  end
end
