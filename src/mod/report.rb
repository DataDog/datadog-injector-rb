# ruby-version-min: 1.8.7

CONTEXT = import 'context'

# Codes are deliberately bounded; original class names and messages stay out of metric tags.
ERRORS = [
  ['missing_gem', ['Bundler::GemNotFound', 'Gem::MissingSpecError', 'Gem::MissingSpecVersionError'],
    'incompatible_dependency', 'A required gem could not be found'],
  ['dependency_conflict', ['Bundler::SolveFailure', 'Bundler::VersionConflict', 'Gem::ConflictError'],
    'incompatible_dependency', 'Dependency requirements could not be satisfied'],
  ['remote_source', ['Bundler::HTTPError'],
    'incompatible_environment', 'A remote gem source could not be accessed'],
  ['invalid_gemspec', ['Bundler::GemspecError'],
    'incompatible_dependency', 'A gem specification could not be evaluated'],
  ['invalid_gemfile', ['Bundler::GemfileError', 'Bundler::Dsl::DSLError'],
    'incompatible_dependency', 'A Gemfile could not be evaluated'],
  ['permission_denied', ['Errno::EACCES', 'Errno::EPERM'],
    'incompatible_environment', 'A required operation was denied permission'],
  ['read_only', ['Errno::EROFS'],
    'incompatible_environment', 'A required write targeted a read-only filesystem'],
  ['missing_file', ['Errno::ENOENT'],
    'incompatible_environment', 'A required file or directory could not be found'],
  ['no_space', ['Errno::ENOSPC'],
    'incompatible_environment', 'A required write ran out of filesystem space'],
  ['load_error', ['LoadError'],
    'incompatible_component', 'A required Ruby component could not be loaded'],
  ['syntax_error', ['SyntaxError'],
    'incompatible_component', 'Ruby source could not be parsed'],
  ['unknown', [],
    'internal_error', 'An unexpected exception was caught during injection'],
]

class << self
  def reason(stage, exception)
    exceptions = if exception.is_a?(CONTEXT::IsolatedError)
                   [{ :ancestors => exception.original_ancestors }] + exception.causes
                 else
                   CONTEXT::IsolatedError.capture(exception)[:exceptions]
                 end

    exceptions.each do |error|
      match = ERRORS.find { |entry| !(entry[1] & error[:ancestors]).empty? }
      return "#{stage}.#{match[0]}" if match
    end

    "#{stage}.unknown"
  end

  def error_for(reason)
    suffix = reason.to_s.split('.').last
    ERRORS.find { |entry| entry[0] == suffix }
  end
  private :error_for

  def class_of(reason)
    error = error_for(reason)
    return error[2] if error

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

    # error reasons
    when 'bundler.inject'                then 'incompatible_dependency'

    # fallback
    else                                      'unknown'
    end
  end

  def text_for(reason, value=nil)
    error = error_for(reason)
    return "#{reason.sub(/\.[^.]+$/, '')}: #{error[3]}" if error

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

  def completed(injected)
    { :result => 'success', :result_reason => 'Successfully configured datadog for injection', :result_class => 'success' }
  end
end
