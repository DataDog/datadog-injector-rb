# ruby-version-min: 1.8.7

class << self
  def call(status)
    result = []

    if status[:ruby][:version] < '2.4.'
      result << { :name => 'ruby.version', :reason => 'runtime.parser' }
    end

    if status[:ruby][:version] < '2.6.'
      result << { :name => 'ruby.version', :reason => 'runtime.version' }
    end

    if status[:ruby][:engine] != 'ruby'
      result << { :name => 'ruby.engine', :reason => 'runtime.engine' }
    end

    if !status[:runtime][:fork]
      result << { :name => 'runtime.fork', :reason => 'runtime.forkless' }
    end

    if lower(status[:bundler][:rubygems], 3, 4, 0)
      result << { :name => 'rubygems.version', :reason => 'rubygems.version' }
    end

    if lower(status[:bundler][:version], 2, 4, 0)
      result << { :name => 'bundler.version', :reason => 'bundler.version' }
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

  def lower(str, exp_maj, exp_min, exp_patch)
    act_maj, act_min, act_patch = str.split('.').take(3).map(&:to_i)

    return true if act_maj < exp_maj
    return true if act_maj == exp_maj && act_min < exp_min
    return true if act_maj == exp_maj && act_min == exp_min && act_patch < exp_patch

    false
  end
end
