# ruby-version-min: 1.8.7

class Conflict < StandardError; end

class Resolver
  def initialize(available, loaded_specs)
    @available = available
    @loaded_specs = loaded_specs
    @failed = {}
  end

  def resolve(root)
    requirements = {}
    add_requirement(requirements, root, 'injection package')

    selected, conflict = search({}, requirements)
    raise Conflict, conflict unless selected

    selected
  end

  private

  def search(selected, requirements)
    if (conflict = selected_conflict(selected, requirements))
      return [nil, conflict]
    end

    unresolved = requirements.keys.reject { |name| selected.key?(name) }
    return [selected, nil] if unresolved.empty?

    state = state_key(selected, requirements)
    return [nil, @failed[state]] if @failed.key?(state)

    name = unresolved.sort_by { |candidate_name| [candidates_for(candidate_name, requirements).length, candidate_name] }.first
    candidates, unavailable = candidates_for(name, requirements, true)

    if candidates.empty?
      conflict = unavailable_message(name, requirements[name], unavailable)
      @failed[state] = conflict
      return [nil, conflict]
    end

    conflicts = []

    candidates.each do |candidate|
      next_selected = selected.dup
      next_selected[name] = candidate
      next_requirements = duplicate_requirements(requirements)

      candidate[:spec].runtime_dependencies.each do |dependency|
        add_requirement(next_requirements, dependency, candidate[:spec].full_name)
      end

      solution, conflict = search(next_selected, next_requirements)
      return [solution, nil] if solution

      conflicts << "#{candidate[:spec].full_name}: #{conflict}"
    end

    conflict = "Unable to resolve #{requirements_text(name, requirements[name])}; tried #{conflicts.join('; ')}"
    @failed[state] = conflict
    [nil, conflict]
  end

  def selected_conflict(selected, requirements)
    requirements.keys.sort.each do |name|
      candidate = selected[name]
      next unless candidate

      unsatisfied = requirements[name].reject do |request|
        request[:dependency].requirement.satisfied_by?(candidate[:spec].version)
      end
      next if unsatisfied.empty?

      suffix = candidate[:source] == :loaded ? ' is already activated' : ' is selected'
      return "#{requirements_text(name, unsatisfied)}, but #{candidate[:spec].full_name}#{suffix}"
    end

    nil
  end

  def candidates_for(name, requirements, include_unavailable = false)
    requests = requirements[name]
    loaded = @loaded_specs[name]
    pool = loaded ? [{ :spec => loaded, :source => :loaded }] : (@available[name] || [])
    available = []
    unavailable = []

    pool.each do |candidate|
      spec = candidate[:spec]

      unless requests.all? { |request| request[:dependency].requirement.satisfied_by?(spec.version) }
        if include_unavailable
          state = candidate[:source] == :loaded ? ' is already activated and does not' : ' does not'
          unavailable << "#{spec.full_name}#{state} satisfy all version requirements"
        end
        next
      end

      if (reason = runtime_incompatibility(spec))
        unavailable << reason if include_unavailable
        next
      end

      available << candidate
    end

    available = available.sort do |left, right|
      source = source_priority(left[:source]) <=> source_priority(right[:source])
      source == 0 ? (right[:spec].version <=> left[:spec].version) : source
    end

    include_unavailable ? [available, unavailable] : available
  end

  def runtime_incompatibility(spec)
    unless spec.required_ruby_version.satisfied_by?(Gem.ruby_version)
      return "#{spec.full_name} does not support Ruby #{Gem.ruby_version}"
    end

    unless spec.required_rubygems_version.satisfied_by?(Gem::Version.new(Gem::VERSION))
      return "#{spec.full_name} does not support RubyGems #{Gem::VERSION}"
    end

    platform_matches = if Gem::Platform.respond_to?(:match_spec?)
                         Gem::Platform.match_spec?(spec)
                       elsif Gem::Platform.respond_to?(:match)
                         Gem::Platform.match(spec.platform)
                       else
                         true
                       end
    unless platform_matches
      return "#{spec.full_name} does not support platform #{Gem::Platform.local}"
    end

    nil
  end

  def source_priority(source)
    case source
    when :loaded then 0
    when :application then 1
    when :package_locked then 2
    else 3
    end
  end

  def add_requirement(requirements, dependency, parent)
    requirements[dependency.name] ||= []
    requirements[dependency.name] << { :dependency => dependency, :parent => parent }
  end

  def duplicate_requirements(requirements)
    copy = {}
    requirements.each { |name, requests| copy[name] = requests.dup }
    copy
  end

  def requirements_text(name, requests)
    details = requests.map { |request| "#{request[:parent]} requires #{request[:dependency]}" }
    "#{name} (#{details.join(', ')})"
  end

  def unavailable_message(name, requests, unavailable)
    message = "No candidate can satisfy #{requirements_text(name, requests)}"
    unavailable.empty? ? "#{message}; no candidate is available" : "#{message}; #{unavailable.join(', ')}"
  end

  def state_key(selected, requirements)
    chosen = selected.keys.sort.map do |name|
      candidate = selected[name]
      "#{name}=#{candidate[:spec].full_name}@#{candidate[:source]}"
    end
    requested = requirements.keys.sort.map do |name|
      values = requirements[name].map do |request|
        "#{request[:dependency].requirement}:#{request[:parent]}"
      end.sort
      "#{name}=#{values.join('&')}"
    end

    "#{chosen.join('|')}::#{requested.join('|')}"
  end
end
