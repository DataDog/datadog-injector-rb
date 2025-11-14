# ruby-version-min: 1.8.7

PROCESS = import 'process'
LOG = import 'log'
RUBY = import 'ruby'
JSON = import 'json'

class << self
  def payload(pid, version, result, points)
    metadata = {
          :language_name => 'ruby',
          :language_version => RUBY.version,
          :runtime_name => RUBY.engine,
          :runtime_version => RUBY.engine_version,
          :tracer_version => version,
          :pid => pid,
        }

    if result
      metadata[:result] = result[:result]
      metadata[:result_reason] = result[:result_reason]
      metadata[:result_class] = result[:result_class]
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

    forwarder = ENV['DD_TELEMETRY_FORWARDER_PATH']

    return unless forwarder && !forwarder.empty?

    rd, wr = IO.pipe

    opt = ENV.delete('RUBYOPT')
    pid = PROCESS.spawn(forwarder, 'library_entrypoint', { :in => rd, [:out, :err] => '/dev/null' })
    ENV['RUBYOPT'] = opt if opt

    wr.write(payload(pid, version, result, points))
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
