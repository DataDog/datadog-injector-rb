# ruby-version-min: 1.8.7

PROCESS = import 'process'
LOG = import 'log'
RUBY = import 'ruby'
JSON = import 'json'

class << self
  def payload(*args)
    pid = args.shift
    version = args.shift

    if args.length > 1
      result = args.shift
      result_reason = args.shift  
      result_class = args.shift
      points = args.shift
    else
      result = nil
      result_reason = nil
      result_class = nil
      points = args.shift
    end

    metadata = {
          :language_name => 'ruby',
          :language_version => RUBY.version,
          :runtime_name => RUBY.engine,
          :runtime_version => RUBY.engine_version,
          :tracer_version => version,
          :pid => pid,
        }

    if result
      metadata[:result] = result
      metadata[:result_reason] = result_reason
      metadata[:result_class] = result_class
    end

    JSON.dump(
      {
        :metadata => metadata,
        :points => points,
      }
    )
  end
  private :payload

  def emit(*args)
    opts = args.last.is_a?(Hash) ? args.pop : {}
    points = args.shift

    LOG.info { "telemetry:emit points:#{points.inspect}" }

    pid = opts[:pid] || PROCESS.pid # TODO: emit from isolate
    version = opts[:version] || package_version
    result = opts[:result]
    result_reason = opts[:result_reason]
    result_class = opts[:result_class]

    forwarder = ENV['DD_TELEMETRY_FORWARDER_PATH']

    return unless forwarder && !forwarder.empty?

    rd, wr = IO.pipe

    pid = PROCESS.spawn(forwarder, 'library_entrypoint', { :in => rd, [:out, :err] => '/dev/null' })

    wr.write(payload(pid, version, result, result_reason, result_class, points))
    wr.flush
    wr.close

    cpid, status = Process.waitpid2(pid)

    LOG.info { "telemetry:forwarder cpid:#{cpid} status:#{status}" }
  end

  # TODO: extract to a package module
  def package_basepath
    ENV['DD_INTERNAL_RUBY_INJECTOR_BASEPATH'] || File.expand_path(File.join(File.dirname(__FILE__), '..'))
  end
  private :package_basepath

  # TODO: extract to a package module
  def package_version
    return unless File.exist?("#{package_basepath}/version")

    File.read("#{package_basepath}/version").chomp
  end
  private :package_version
end
