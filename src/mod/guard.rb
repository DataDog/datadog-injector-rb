# ruby-version-min: 1.8.7

class << self
  def call(status)
    result = []

    if lower(status[:ruby][:version], 2, 4)
      result << { :name => 'ruby.version', :reason => 'runtime.parser', :value => status[:ruby][:version] }
    end

    if lower(status[:ruby][:version], 2, 6)
      result << { :name => 'ruby.version', :reason => 'runtime.version', :value => status[:ruby][:version] }
    end

    if status[:ruby][:engine] != 'ruby'
      result << { :name => 'ruby.engine', :reason => 'runtime.engine', :value => status[:ruby][:engine] }
    end

    if !status[:runtime][:fork]
      result << { :name => 'runtime.fork', :reason => 'runtime.forkless' }
    end

    if lower(status[:bundler][:rubygems], 3, 4, 0)
      result << { :name => 'rubygems.version', :reason => 'rubygems.version', :value => status[:bundler][:rubygems] }
    end

    if lower(status[:bundler][:version], 2, 4, 0)
      result << { :name => 'bundler.version', :reason => 'bundler.version', :value => status[:bundler][:version] }
    end

    if min(status[:bundler][:rubygems], 4, 0, 0)
      result << { :name => 'rubygems.version', :reason => 'rubygems.version', :value => status[:bundler][:rubygems] }
    end

    if min(status[:bundler][:version], 4, 0, 0)
      result << { :name => 'bundler.version', :reason => 'bundler.version', :value => status[:bundler][:version] }
    end

    if min(status[:bundler][:simulate_version], 4, 0, 0)
      result << { :name => 'bundler.version.simulated', :reason => 'bundler.version.simulated', :value => status[:bundler][:simulate_version] }
    end

    if !status[:bundler][:bundled]
      result << { :name => 'bundler.bundled', :reason => 'bundler.unbundled' }
    end

    if !status[:bundler][:locked]
      result << { :name => 'bundler.locked', :reason => 'bundler.unlocked' }
    end

    if status[:bundler][:frozen]
      result << { :name => 'bundler.frozen', :reason => 'bundler.frozen' }
    end

    if !status[:fs][:writable]
      result << { :name => 'fs.writable', :reason => 'fs.readonly' }
    end

    if status[:bundler][:deployment]
      result << { :name => 'bundler.deployment', :reason => 'bundler.deployment' }
    end

    if !status[:bundler][:use_system_gems]
      result << { :name => 'bundler.use_system_gems', :reason => 'bundler.vendored' }
    end

    result unless result.empty?
  end

  def lower(str, exp_maj, exp_min=0, exp_patch=0)
    act_maj, act_min, act_patch = str.to_s.split('.').take(3).map(&:to_i)

    act_maj   ||= 0
    act_min   ||= 0
    act_patch ||= 0

    return true if act_maj < exp_maj
    return true if act_maj == exp_maj && act_min < exp_min
    return true if act_maj == exp_maj && act_min == exp_min && act_patch < exp_patch

    false
  end

  def min(str, exp_maj, exp_min=0, exp_patch=0)
    act_maj, act_min, act_patch = str.to_s.split('.').take(3).map(&:to_i)

    act_maj   ||= 0
    act_min   ||= 0
    act_patch ||= 0

    return true if act_maj > exp_maj
    return true if act_maj == exp_maj && act_min > exp_min
    return true if act_maj == exp_maj && act_min == exp_min && act_patch >= exp_patch

    false
  end
end
