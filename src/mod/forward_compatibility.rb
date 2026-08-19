# ruby-version-min: 1.8.7

class << self
  # The mutating injector depends on Bundler internals tested through
  # Bundler/RubyGems 4. Future component versions use the supported setup and
  # gem activation surfaces instead. This does not expand Ruby support: the
  # injector guard and packaged Datadog gem metadata remain authoritative.
  def required?(status)
    rubygems?(status) || bundler?(status) || simulated_bundler?(status)
  end

  def rubygems?(status)
    at_least(status[:bundler][:rubygems], 5, 0, 0)
  end

  def bundler?(status)
    at_least(status[:bundler][:version], 5, 0, 0)
  end

  def simulated_bundler?(status)
    at_least(status[:bundler][:simulate_version], 5, 0, 0)
  end

  def at_least(str, exp_maj, exp_min=0, exp_patch=0)
    act_maj, act_min, act_patch = str.to_s.split('.').take(3).map(&:to_i)

    act_maj   ||= 0
    act_min   ||= 0
    act_patch ||= 0

    return true if act_maj > exp_maj
    return true if act_maj == exp_maj && act_min > exp_min
    return true if act_maj == exp_maj && act_min == exp_min && act_patch >= exp_patch

    false
  end
  private :at_least
end
