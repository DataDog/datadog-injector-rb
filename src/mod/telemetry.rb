# ruby-version-min: 1.8.7

PROCESS = import 'process'
LOG = import 'log'
RUBY = import 'ruby'
TRACER = import 'tracer'
JSON = import 'json'

class << self
  def payload(pid, version, points)
    JSON.dump(
      {
        :metadata => {
          :language_name => 'ruby',
          :language_version => RUBY.version,
          :runtime_name => RUBY.engine,
          :runtime_version => RUBY.engine_version,
          :tracer_version => version,
          :pid => pid,
        },
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
    version = opts[:version] || TRACER.version

    forwarder = ENV['DD_TELEMETRY_FORWARDER_PATH']

    return unless forwarder && !forwarder.empty?

    rd, wr = IO.pipe

    pid = PROCESS.spawn(forwarder, 'library_entrypoint', { :in => rd, [:out, :err] => '/dev/null' })
  # pid = PROCESS.spawn(forwarder, 'library_entrypoint', { :in => rd })

    wr.write(payload(pid, version, points))
    wr.flush
    wr.close

    cpid, status = Process.waitpid2(pid)

    LOG.info { "telemetry:forwarder cpid:#{cpid} status:#{status}" }
  end
end
