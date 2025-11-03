# ruby-version-min: 1.8.7

class << self
  def status
    require!

    {
      :rubygems          => Gem::VERSION,
      :gem_path          => Gem.path,
      :version           => Bundler::VERSION,
      :simulate_version  => Bundler.settings[:simulate_version],
      :gemfile           => (Bundler.default_gemfile rescue nil),
      :lockfile          => (Bundler.default_lockfile rescue nil),
      :bundled           => Bundler::SharedHelpers.in_bundle?,
      :locked            => (Bundler.default_lockfile.exist? rescue nil),
      :frozen            => Bundler.frozen_bundle?,
      :deployment        => Bundler.settings[:deployment],
      :root              => (Bundler.root rescue nil),
      :bundle_path       => (Bundler.bundle_path rescue nil),
      :use_system_gems   => (Bundler.settings.path.use_system_gems? rescue nil),
      :home              => (Bundler.home rescue nil),
      :install_path      => (Bundler.install_path rescue nil),
      :app_config_path   => (Bundler.app_config_path rescue nil),
      :settings => {
        :gem_home        => ENV['GEM_HOME'],
        :gem_path        => ENV['GEM_PATH'],
        :gemfile         => Bundler.settings[:gemfile],
        :deployment      => Bundler.settings[:deployment],
        :frozen          => Bundler.settings[:frozen],
        :path            => Bundler.settings[:path],
        :app_config      => Bundler.settings[:app_config],
      },
    }
  end

  def patch!
    require!

    mod = Module.new do
      def [](name)

        if name == :deployment
          return false
        end

        super
      end
    end

    ::Bundler::Settings.prepend mod
  end

  private

  def require!
    # require rubygems first, otherwise there may be a per-file mixup between
    # bundler versions (observed: stdlib vs gem home)
    require 'rubygems'

    require 'bundler'
  end
end
