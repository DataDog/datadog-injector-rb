# ruby-version-min: 1.8.7

# Main module
#
# This module gets evaluated immediately

telemetry = import 'telemetry'
process = import 'process'

# Emit start immediately
telemetry.emit([{ :name => 'library_entrypoint.start' }])

log = import 'log'

REASON_CLASS_MAP = {
  /^runtime\./ => 'incompatible_runtime',
  /^fs\./ => 'incompatible_environment',
  'rubygems.version' => 'incompatible_component',
  'bundler.version' => 'incompatible_component',
  'bundler.unbundled' => 'unsupported_binary',
  'bundler.unlocked' => 'incompatible_component',
  'bundler.frozen' => 'incompatible_component',
  'bundler.deployment' => 'incompatible_environment',
  'bundler.vendored' => 'incompatible_environment'
}

def self.classify_user_reason(reason)
  return nil unless reason
  REASON_CLASS_MAP.each do |pattern, classification|
    return classification if pattern.is_a?(Regexp) ? reason =~ pattern : reason == pattern
  end
  'unknown'
end

# TODO: config

# stage 1: gather context
context = import 'context'

log.info { "context: #{context.status.inspect}" }

# stage 2: check context against requirements
guard = import 'guard'

if (result = guard.call(context.status))
  log.info { "guard:call result:#{result.inspect}" }

  tags = result.map { |r| "reason:#{r[:reason]}" }

  if result.size == 1
  # Pick the first reason for UI consumption
    user_reason = result.map { |r| r[:reason] }.compact.first
    user_reason_class = self.classify_user_reason(user_reason)
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
