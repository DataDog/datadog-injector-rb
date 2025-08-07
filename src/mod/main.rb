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

  # TODO: check logic
  if result.size == 1
    # report guardrail for UI consumption
    # TODO: we pick the first one
    user_reason = result.map { |r| r[:reason] }.compact.first

    # TODO: this processing should be extracted
    if user_reason =~ /^runtime\./
      # Runtime version or engine is incompatible
      user_reason_class = 'incompatible_runtime'
    elsif user_reason =~ /^fs\./
      # The environmetn within which the application runs has been deemed unsatisfactory
      user_reason_class = 'incompatible_environment'
    elsif ['rubygems.version', 'bundler_version'].include?(user_reason)
      # The version of these components are incompatible but could be upgraded spearately of the runtime
      user_reason_class = 'incompatible_component'
    elsif ['bundler.unbundled'].include?(user_reason)
      # We can't inject outside of a Bundler context
      user_reason_class = 'unsupported_binary'
    else
      # Theoretically we don't reach this
      # TODO: cover all cases that are present in guardrails
      user_reason_class = 'unknown'
    end

  else
    user_reason_class = 'multiple_reasons'
  end

  # TODO: map codes to user-oriented text
  reason_text = result.map { |r| r[:reason] }.join(', ')

  telemetry.emit([
    { :name => 'library_entrypoint.abort', :tags => tags },
  ], { :result => 'abort', :result_reason => reason_text, :result_class => user_reason_class })

# stage 3: inject
else
  log.info { 'inject:proceed' }

  injector = import 'injector'

  if ENV['DD_INTERNAL_RUBY_INJECTOR'] == 'false'
    log.info { 'inject:skip' }

    telemetry.emit([
      { :name => 'library_entrypoint.complete', :tags => ["reason:internal.skip"] },
    ], { :result => 'success', :result_reason => 'Successfully reused previous datadog injection', :result_class => 'success_cached' })
  else
    begin
      # TODO: pass args, e.g context, location, etc...
      injected, err = injector.call

      if err
        # TODO: match err to user reason class and user reason text
        # TODO: improve reporting accuracy on the injector.call side
        telemetry.emit([
          { :name => 'library_entrypoint.error', :tags => ["reason:#{err}"] },
        ], { :result => 'error', :result_reason => 'A dependency was found to be incompatible', :result_class => 'incompatible_dependency' })
      else
        log.info { 'inject:complete' }

        telemetry.emit([
          { :name => 'library_entrypoint.complete' },
        ], { :result => 'success', :result_reason => 'Successfully configured datadog for injection', :result_class => 'success' })
      end
    rescue StandardError => _e
      log.info { 'inject:error' }

      telemetry.emit([
        { :name => 'library_entrypoint.error', :tags => ["reason:exc.fatal"] },
      ], { :result => 'error', :result_reason => 'library_entrypoint.error', :result_class => 'internal_error' })
    end
  end
end
