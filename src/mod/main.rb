# ruby-version-min: 1.8.7

# Main module
#
# This module gets evaluated immediately

telemetry = import 'telemetry'
process = import 'process'

# Emit start immediately
telemetry.emit([{ :name => 'library_entrypoint.start' }])

log = import 'log'

# TODO: config

# stage 1: gather context
context = import 'context'

log.info { "context: #{context.status.inspect}" }

# stage 2: check context against requirements
guard = import 'guard'

if (result = guard.call(context.status))
  log.info { "guard:call result:#{result.inspect}" }

  tags = result.map { |r| "reason:#{r[:reason]}" }

  telemetry.emit([
    { :name => 'library_entrypoint.abort', :tags => tags },
  ])

# stage 3: inject
else
  telemetry.emit([
    { :name => 'library_entrypoint.proceed' },
  ])
  log.info { 'inject:proceed' }

  injector = import 'injector'

  if ENV['DD_INTERNAL_RUBY_INJECTOR'] == 'false'
    telemetry.emit([
      { :name => 'library_entrypoint.complete', :tags => ["reason:internal.skip"] },
    ])
  else
    begin
      # TODO: pass args, e.g context, location, etc...
      injected, err = injector.call

      if err
        telemetry.emit([
          { :name => 'library_entrypoint.error', :tags => ["reason:#{err}"] },
        ])
      else
        telemetry.emit([
          { :name => 'library_entrypoint.succeed' },
        ])

        log.info { 'inject:complete' }

        telemetry.emit([
          { :name => 'library_entrypoint.complete' },
        ])
      end
    rescue StandardError => _e
      telemetry.emit([
        { :name => 'library_entrypoint.error', :tags => ["reason:exc.fatal"] },
      ])
    end
  end
end
