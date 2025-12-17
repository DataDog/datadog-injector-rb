# ruby-version-min: 1.8.7

class << self
  def class_of(reason)
    case reason

    # safety
    when nil                             then nil

    # abort reasons
    when /^runtime\./                    then 'incompatible_runtime'
    when /^fs\./                         then 'incompatible_environment'
    when 'rubygems.version'              then 'incompatible_component'
    when 'bundler.version'               then 'incompatible_component'
    when 'bundler.unbundled'             then 'unsupported_binary'
    when 'bundler.unlocked'              then 'incompatible_component'
    when 'bundler.vendored'              then 'incompatible_environment'
    when 'bundler.version.simulated'     then 'incompatible_environment'
    when 'bundler.platform.forced'       then 'incompatible_environment'

    # error reasons
    when 'bundler.inject'                then 'incompatible_dependency'

    # fallback
    else                                      'unknown'
    end
  end

  def text_for(reason, value=nil)
    case reason

    # safety
    when nil
      nil

    # abort reasons
    when 'runtime.parser'
      "The Ruby runtime language parser cannot parse the injected code (expected:2.4+ actual:#{value})"
    when 'runtime.version'
      "The Ruby runtime language version is insufficient to execute the injected code (expected:2.6+ actual:#{value})"
    when 'runtime.engine'
      "The Ruby runtime engine (#{value}) is not compatible"
    when 'runtime.forkless'
      'The Ruby runtime does not support forking'
    when 'rubygems.version'
      "The Ruby runtime 'rubygems' component version in use is too low (expected:[3.4+,<4.0] actual:#{value})"
    when 'bundler.version'
      "The Ruby runtime 'bundler' component version in use is out of range (expected:[2.4+,<4.0] actual:#{value})"
    when 'bundler.version.simulated'
      "Bundler is configured to simulate an incompatible version (expected:<4.0 actual:#{value})"
    when 'bundler.unbundled'
      'The Ruby process is not running in a bundle (no Gemfile found)'
    when 'bundler.unlocked'
      'The Ruby process has no dependency lock (no Gemfile.lock found)'
    when 'bundler.vendored'
      'Bundler is configured to ignore gems out of the vendored path'
    when 'bundler.platform.forced'
      'Bundler is configured to force an incompatible or restricted gem platform'
    when 'fs.readonly'
      'The Gemfile directory is read-only'

    # error reasons
    when 'bundler.inject'
      'A dependency was found to be incompatible'

    # fallback
    else
      "Reason: '#{reason}'"
    end
  end

  def aborted(result)
    reason_class = result.size == 1 ? class_of(result.first[:reason]) : 'multiple_reasons'
    reason_text = result.map { |r| text_for(r[:reason], r[:value]) }.compact.join(', ')

    { :result => 'abort', :result_reason => reason_text, :result_class => reason_class }
  end

  def cached
    { :result => 'success', :result_reason => 'Successfully reused previous datadog injection', :result_class => 'success_cached' }
  end

  def errored(err)
    { :result => 'error', :result_reason => text_for(err), :result_class => class_of(err) }
  end

  def raised(exc)
    { :result => 'error', :result_reason => 'An internal exception was caught during injection', :result_class => 'internal_error' }
  end

  def completed(injected)
    { :result => 'success', :result_reason => 'Successfully configured datadog for injection', :result_class => 'success' }
  end
end
