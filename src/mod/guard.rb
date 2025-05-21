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

    if !status[:fs][:writable]
      result << { :name => 'fs.writable', :reason => 'fs.readonly' }
    end

    result unless result.empty?
  end
end
