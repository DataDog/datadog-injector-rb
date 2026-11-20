# ruby-version-min: 1.8.7

TELEMETRY = import 'telemetry'
REPORT = import 'report'

TELEMETRY.emit([{ :name => 'library_entrypoint.start' }])

class << self
  def abort(reason)
    TELEMETRY.emit([
      { :name => 'library_entrypoint.abort', :tags => ["reason:#{reason}"] },
    ], { :result => REPORT.aborted([{ :reason => reason }]) })
  end

  def run
    return if @owner == Thread.current

    @mutex.synchronize do
      return unless @pending

      @pending = false
      @owner = Thread.current
      @trace.disable
      # Injector calls, including in its forked children, must not re-enter.
      # Other setup callers wait until the environment is ready.
      begin
        import 'main'
      ensure
        @hooks.each { |hook, name| hook.send(:remove_method, name) }
        @hooks.clear
        @owner = nil
      end
    end
  end

  def watch(target, name)
    return unless target.respond_to?(name)
    return if @hooks.any? { |hook, method| method == name }

    intent = self
    hook = Module.new do
      define_method(name) do |*args|
        intent.run
        super(*args)
      end
    end
    target.singleton_class.prepend(hook)
    @hooks << [hook, name]
  end

  def observe(target)
    return unless target.is_a?(Module)

    case target.name
    when 'Bundler' then watch(target, :setup)
    when 'Bundler::CLI' then watch(target, :start)
    end
  end

  def defer
    if Object.const_defined?(:Bundler) && !Object.autoload?(:Bundler) && ::Bundler.instance_variable_get(:@setup)
      # Recent Bundler can set up an exec'd VM before RUBYOPT runs. Its parent
      # has already selected the injected bundle; retain the cached path.
      if ENV['DD_INTERNAL_RUBY_INJECTOR'] == 'false'
        import 'main'
      else
        abort('bundler.active')
      end
      return
    end

    @pending = true
    @hooks = []
    @mutex = Mutex.new
    # Class/module completion observes Bundler without loading or selecting it.
    # Unlike a call trace, this adds no per-method overhead to unbundled apps.
    @trace = TracePoint.new(:end) { |event| observe(event.self) }
    @trace.enable
    if Object.const_defined?(:Bundler) && !Object.autoload?(:Bundler)
      observe(::Bundler)
      observe(::Bundler::CLI) if ::Bundler.const_defined?(:CLI) && !::Bundler.autoload?(:CLI)
    end
    at_exit { abort('bundler.unrequested') if @pending }
  end
end

if defined?(TracePoint) && Module.method_defined?(:prepend)
  defer
else
  abort('runtime.parser')
end
