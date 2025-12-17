# ruby-version-min: 1.8.7

class << self
  def call(status)
    result = []

    if !status[:inject][:ruby][:force]['ruby.version'] && lower(status[:ruby][:version], 2, 4)
      result << { :name => 'ruby.version', :reason => 'runtime.parser', :value => status[:ruby][:version] }
    end

    if !status[:inject][:ruby][:force]['ruby.version'] && lower(status[:ruby][:version], 2, 6)
      result << { :name => 'ruby.version', :reason => 'runtime.version', :value => status[:ruby][:version] }
    end

    # actually, exclude all previews?
    if !status[:inject][:ruby][:force]['ruby.version'] && min(status[:ruby][:version], 3, 5)
      result << { :name => 'ruby.version', :reason => 'runtime.version' , :value => status[:ruby][:version]}
    end

    if !status[:inject][:ruby][:force]['ruby.engine'] && status[:ruby][:engine] != 'ruby'
      result << { :name => 'ruby.engine', :reason => 'runtime.engine', :value => status[:ruby][:engine] }
    end

    if !status[:inject][:ruby][:force]['runtime.fork'] && !status[:runtime][:fork]
      result << { :name => 'runtime.fork', :reason => 'runtime.forkless' }
    end

    if !status[:inject][:ruby][:force]['rubygems.version'] && lower(status[:bundler][:rubygems], 3, 4, 0)
      result << { :name => 'rubygems.version', :reason => 'rubygems.version', :value => status[:bundler][:rubygems] }
    end

    if !status[:inject][:ruby][:force]['bundler.version'] && lower(status[:bundler][:version], 2, 4, 0)
      result << { :name => 'bundler.version', :reason => 'bundler.version', :value => status[:bundler][:version] }
    end

    if !status[:inject][:ruby][:force]['rubygems.version'] && min(status[:bundler][:rubygems], 4, 0, 0)
      result << { :name => 'rubygems.version', :reason => 'rubygems.version', :value => status[:bundler][:rubygems] }
    end

    if !status[:inject][:ruby][:force]['bundler.version'] && min(status[:bundler][:version], 4, 0, 0)
      result << { :name => 'bundler.version', :reason => 'bundler.version', :value => status[:bundler][:version] }
    end

    if !status[:inject][:ruby][:force]['bundler.version.simulated'] && min(status[:bundler][:simulate_version], 4, 0, 0)
      result << { :name => 'bundler.version.simulated', :reason => 'bundler.version.simulated', :value => status[:bundler][:simulate_version] }
    end

    if !status[:inject][:ruby][:force]['bundler.bundled'] && !status[:bundler][:bundled]
      result << { :name => 'bundler.bundled', :reason => 'bundler.unbundled' }
    end

    if !status[:inject][:ruby][:force]['bundler.locked'] && !status[:bundler][:locked]
      result << { :name => 'bundler.locked', :reason => 'bundler.unlocked' }
    end

    if !status[:inject][:ruby][:force]['bundler.path'] && status[:bundler][:settings][:path]
      result << { :name => 'bundler.path', :reason => 'bundler.vendored' }
    end

    if !status[:inject][:ruby][:force]['fs.writable'] && !status[:fs][:writable]
      result << { :name => 'fs.writable', :reason => 'fs.readonly' }
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
