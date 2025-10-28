# ruby-version-min: 1.8.7

class << self
  def class_of(reason)
    case reason
    when nil                    then nil
    when /^runtime\./           then 'incompatible_runtime'
    when /^fs\./                then 'incompatible_environment'
    when 'rubygems.version'     then 'incompatible_component'
    when 'bundler.version'      then 'incompatible_component'
    when 'bundler.unbundled'    then 'unsupported_binary'
    when 'bundler.unlocked'     then 'incompatible_component'
    when 'bundler.frozen'       then 'incompatible_component'
    when 'bundler.deployment'   then 'incompatible_environment'
    when 'bundler.vendored'     then 'incompatible_environment'
    else                             'unknown'
    end
  end

  def aborted(result)
    reason_class = result.size == 1 ? class_of(result.first[:reason]) : 'multiple_reasons'

    # TODO: map codes to user-oriented text
    reason_text = result.map { |r| r[:reason] }.join(', ')

    { :result => 'abort', :result_reason => reason_text, :result_class => reason_class }
  end

  def cached
    { :result => 'success', :result_reason => 'Successfully reused previous datadog injection', :result_class => 'success_cached' }
  end

  def errored(err)
    # TODO: match err to user reason class and user reason text
    # TODO: improve reporting accuracy on the injector.call side

    { :result => 'error', :result_reason => 'A dependency was found to be incompatible', :result_class => 'incompatible_dependency' }
  end

  def raised(exc)
    { :result => 'error', :result_reason => 'library_entrypoint.error', :result_class => 'internal_error' }
  end

  def completed(injected)
    { :result => 'success', :result_reason => 'Successfully configured datadog for injection', :result_class => 'success' }
  end
end
