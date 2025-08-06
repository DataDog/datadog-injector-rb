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
  ], { :result => 'abort', :result_reason => 'library_entrypoint.abort', :result_class => 'internal_error' })

# stage 3: inject
else
  log.info { 'inject:proceed' }

  injector = import 'injector'

  if ENV['DD_INTERNAL_RUBY_INJECTOR'] == 'false'
    log.info { 'inject:skip' }

    telemetry.emit([
      { :name => 'library_entrypoint.complete', :tags => ["reason:internal.skip"] },
    ], { :result => 'abort', :result_reason => 'inject:skip', :result_class => 'internal_error' })
  else
    begin
      # TODO: pass args, e.g context, location, etc...
      injected, err = injector.call

      if err
        telemetry.emit([
          { :name => 'library_entrypoint.error', :tags => ["reason:#{err}"] },
        ], { :result => 'error', :result_reason => err.to_s, :result_class => 'internal_error' })
      else
        log.info { 'inject:complete' }

        telemetry.emit([
          { :name => 'library_entrypoint.complete' },
        ], { :result => 'success', :result_reason => 'Successfully configured ddtrace package', :result_class => 'success' })
      end
    rescue StandardError => _e
      log.info { 'inject:error' }

      telemetry.emit([
        { :name => 'library_entrypoint.error', :tags => ["reason:exc.fatal"] },
      ], { :result => 'error', :result_reason => 'library_entrypoint.error', :result_class => 'internal_error' })
    end
  end
end
