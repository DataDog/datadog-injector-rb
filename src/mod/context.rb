# ruby-version-min: 1.8.7

PROCESS = import 'process'
BUNDLER = import 'bundler'
RUBY = import 'ruby'
RUNTIME = import 'runtime'

class << self
  def isolate(&block)
    # HACK: until context[:bundler] evaluation can be figured out for JRuby
    return block.call unless Process.respond_to?(:fork)

    PROCESS.child_eval do
      begin
        $stdout.reopen('/dev/null', 'w')
        $stderr.reopen('/dev/null', 'w')

        result = primitive(block.call)
      rescue Exception => e
        exc = StandardError.new "#{e.class.name}: #{e.message}"
        exc.set_backtrace(e.backtrace)
      end

      # raise outside of rescue to not set Exception#cause
      raise exc if exc

      result
    end
  end

  def primitive(val)
    case val
    when String, Symbol, Integer, Float, TrueClass, FalseClass, NilClass
      val
    when Array
      val.map { |v| primitive(v) }
    when Hash
      Hash[val.map { |k, v| [primitive(k), primitive(v)] }]
    else
      val.to_s
    end
  end
  private :primitive

  def package
    # TODO: extract to a package module

    package_basepath = ENV['DD_INTERNAL_RUBY_INJECTOR_BASEPATH'] || File.expand_path(File.join(File.dirname(__FILE__), '..'))
    package_gem_home = ENV['DD_INTERNAL_RUBY_INJECTOR_GEM_HOME'] || File.join(package_basepath, 'ruby', RUBY.api_version)
    package_lockfile = ENV['DD_INTERNAL_RUBY_INJECTOR_LOCKFILE'] || File.join(package_gem_home, 'Gemfile.lock')

    package_version_file = File.join(package_basepath, 'version')
    package_version = File.read(package_version_file).chomp if File.exist?(package_version_file)

    {
      :basepath => package_basepath,
      :gem_home => package_gem_home,
      :lockfile => package_lockfile,
      :version => package_version,
    }
  end

  def fs(bundler)
    target = (bundler[:gemfile] ? File.dirname(bundler[:gemfile]) : Dir.pwd)

    # TODO: make a list of candidate targets and whether they're writable or not
    # e.g this could work, unless the app's Gemfile has relative references...
    #
    #     if File.writable?(File.join(app_root, 'tmp'))
    #       targets << File.join(app_root, 'tmp', 'datadog')
    #     end

    {
      :target => target,
      :writable => File.writable?(target)
    }
  end
  private :fs

  def eval
    bundler = isolate { BUNDLER.status }

    {
      :inject => {
        :preload => {},
        :ruby => {
          :package => package,
          :force => Hash[ENV['DD_INTERNAL_RUBY_INJECTOR_FORCE'].tap { |s| break(s && s.split(',').map(&:strip) || []) }.map { |k| [k, true] }]
        },
      },
      :ruby => {
        :version => RUBY.version,
        :api_version => RUBY.api_version,
        :engine => RUBY.engine,
        :engine_version => RUBY.engine_version,
        :platform => RUBY.platform,
      },
      :process => {
        :exe => PROCESS.exe,
        :name => PROCESS.name,
        :args => PROCESS.args,
        :cmdline => PROCESS.cmdline,
        :wd => Dir.pwd,
      },
      :fs => fs(bundler),
      :runtime => {
        :fork => Process.respond_to?(:fork),
        :spawn => Process.respond_to?(:spawn),
        :platform => RUNTIME.platform,
        :version => RUNTIME.version,
        :name => RUNTIME.name,
      },
      :bundler => bundler
    }
  end
end
