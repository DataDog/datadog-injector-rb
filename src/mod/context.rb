# ruby-version-min: 1.8.7

PROCESS = import 'process'
BUNDLER = import 'bundler'
RUBY = import 'ruby'
RUNTIME = import 'runtime'

class << self
  def isolate(&block)
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

  def status
    {
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
      },
      :fs => {
        :writable => File.writable?(Dir.pwd),
      },
      :runtime => {
        :fork => Process.respond_to?(:fork),
        :spawn => Process.respond_to?(:spawn),
        :platform => RUNTIME.platform,
        :version => RUNTIME.version,
        :name => RUNTIME.name,
      },
      :bundler => isolate { BUNDLER.status }
    }
  end
end
