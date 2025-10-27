# ruby-version-min: 1.8.7

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

class << self
  def classify_user_reason(reason)
    return nil unless reason
    REASON_CLASS_MAP.each do |pattern, classification|
      return classification if pattern.is_a?(Regexp) ? reason =~ pattern : reason == pattern
    end
    'unknown'
  end

  def aborted(result)
    if result.size == 1
    # Pick the first reason for UI consumption
      user_reason = result.map { |r| r[:reason] }.compact.first
      user_reason_class = self.classify_user_reason(user_reason)
    else
      user_reason_class = 'multiple_reasons'
    end
    # TODO: map codes to user-oriented text
    reason_text = result.map { |r| r[:reason] }.join(', ')

    { :result => 'abort', :result_reason => reason_text, :result_class => user_reason_class }
  end

  def cached
    { :result => 'success', :result_reason => 'Successfully reused previous datadog injection', :result_class => 'success_cached' }
  end

  def errored(err)
    # TODO: match err to user reason class and user reason text
    # TODO: improve reporting accuracy on the injector.call side

    { :result => 'error', :result_reason => 'A dependency was found to be incompatible', :result_class => 'incompatible_dependency' }
  end

  def raised(e)
    { :result => 'error', :result_reason => 'library_entrypoint.error', :result_class => 'internal_error' }
  end

  def completed
    { :result => 'success', :result_reason => 'Successfully configured datadog for injection', :result_class => 'success' }
  end
end
