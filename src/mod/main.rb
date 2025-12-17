# ruby-version-min: 1.8.7

# Main module
#
# This module gets evaluated immediately

telemetry = import 'telemetry'
process = import 'process'

# Emit start immediately
telemetry.emit([{ :name => 'library_entrypoint.start' }])

log = import 'log'
report = import 'report'

# TODO: config

# stage 1: gather context
context = import 'context'

context_status = begin
                   context.eval
                 rescue StandardError => e
                   log.info { "inject:fatal at:context exc:#{e.class.name},#{e.message.inspect},#{e.backtrace.first.inspect}" }

                   telemetry.emit([
                     { :name => 'library_entrypoint.error', :tags => ["reason:exc.fatal"] },
                   ], { :result => report.raised(e) })

                   nil # NOOP: falls through to end
                 end

unless context_status.nil?
  # stage 2: check context against requirements

  log.info { "context: #{context_status.inspect}" }

  guard = import 'guard'

  result = begin
             guard.call(context_status)
           rescue StandardError => e
             log.info { "inject:fatal at:guard exc:#{e.class.name},#{e.message.inspect},#{e.backtrace.first.inspect}" }

             telemetry.emit([
               { :name => 'library_entrypoint.error', :tags => ["reason:exc.fatal"] },
             ], { :result => report.raised(e) })

             :exc
           end

  case result
  when :exc
    # NOOP, falls through to end
  when Array
    log.info { "guard:call result:#{result.inspect}" }

    tags = result.map { |r| "reason:#{r[:reason]}" }

    telemetry.emit([
      { :name => 'library_entrypoint.abort', :tags => tags },
    ], { :result => report.aborted(result) })

  else
    # stage 3: inject

    log.info { 'inject:proceed' }

    injector = import 'injector'

    if ENV['DD_INTERNAL_RUBY_INJECTOR'] == 'false'
      if ENV['DD_INTERNAL_RUBY_INJECTOR_PATCH']
        log.info { 'inject:patch' }

        bundler = import 'bundler'

        bundler.patch!
      else
        log.info { 'inject:skip' }
      end

      telemetry.emit([
        { :name => 'library_entrypoint.complete', :tags => ["reason:internal.skip"] },
      ], { :result => report.cached })
    else
      begin
        # TODO: pass args, e.g context, location, etc...
        injected, err = injector.call(context_status)
      rescue StandardError => e
        log.info { "inject:fatal at:injector exc:#{e.class.name},#{e.message.inspect},#{e.backtrace.first.inspect}" }

        telemetry.emit([
          { :name => 'library_entrypoint.error', :tags => ["reason:exc.fatal"] },
        ], { :result => report.raised(e) })
      end

      if err
        log.info { "inject:error err:#{err.inspect}" }

        telemetry.emit([
          { :name => 'library_entrypoint.error', :tags => ["reason:#{err}"] },
        ], { :result => report.errored(err) })
      else
        log.info { 'inject:complete' }

        telemetry.emit([
          { :name => 'library_entrypoint.complete' },
        ], { :result => report.completed(injected) })
      end
    end
  end
end
