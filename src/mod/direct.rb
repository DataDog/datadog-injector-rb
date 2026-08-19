# ruby-version-min: 1.8.7

BUNDLER = import 'bundler'
RESOLVER = import 'resolver'

class DirectError < StandardError
  attr_reader :cause

  def initialize(message, cause = nil)
    super(message)

    @cause = cause
  end
end

class SetupError < DirectError; end
class ResolutionError < DirectError; end
class LoadError < DirectError; end

class << self
  def call(context)
    # Let `bundle exec` carry the injector into the application process instead
    # of loading Datadog into the short-lived Bundler CLI process.
    return false if bundler_cli?(context)

    package = context[:inject][:ruby][:package]

    setup_bundle

    selected = resolve(package[:gem_home], package[:lockfile])
    activate(selected)

    true
  end

  private

  def bundler_cli?(context)
    name = context[:process][:name]
    name && !!(File.basename(name) =~ /\Abundler?(?:\d+(?:\.\d+)*)?\z/)
  end

  def setup_bundle
    begin
      BUNDLER.send(:require!)
      require 'bundler/setup'
    rescue SystemExit, StandardError => e
      raise SetupError.new('Failed to activate the application bundle', e)
    end
  end

  def resolve(gem_home, lockfile)
    begin
      locked = Bundler::LockfileParser.new(Bundler.read_file(lockfile))
      available = load_candidates(gem_home, locked.specs)
      datadog = locked.dependencies['datadog']

      unless datadog
        raise ResolutionError.new('The injection package does not declare a datadog dependency')
      end

      RESOLVER::Resolver.new(available, Gem.loaded_specs).resolve(datadog)
    rescue RESOLVER::Conflict => e
      raise ResolutionError.new(e.message, e)
    rescue DirectError
      raise
    rescue StandardError => e
      raise ResolutionError.new('Failed to resolve direct injection dependencies', e)
    end
  end

  def load_candidates(gem_home, locked_specs)
    available = {}

    Bundler.load.specs.each do |spec|
      # Datadog comes from the selected injection package. An application copy
      # that is already active is still treated as immutable by the resolver.
      next if spec.name == 'datadog'

      add_candidate(available, spec, :application)
    end

    load_package_candidates(gem_home, locked_specs).each do |candidate|
      add_candidate(available, candidate[:spec], candidate[:source])
    end

    available
  end

  def load_package_candidates(gem_home, locked_specs)
    locked = {}
    locked_specs.each { |spec| locked[[spec.name, spec.version.to_s]] = true }

    candidates = []
    pattern = File.join(gem_home, 'specifications', '*.gemspec')

    Dir[pattern].sort.each do |path|
      spec = Gem::Specification.load(path)
      next unless spec

      is_locked = locked[[spec.name, spec.version.to_s]]

      # The requested Datadog version is canonical, but additional packaged
      # dependency versions are valid alternatives for the local resolver.
      next if spec.name == 'datadog' && !is_locked

      candidates << { :spec => spec, :source => (is_locked ? :package_locked : :package) }
    end

    candidates
  end

  def add_candidate(available, spec, source)
    available[spec.name] ||= []
    duplicate = available[spec.name].any? do |candidate|
      candidate[:spec].version == spec.version && candidate[:spec].platform == spec.platform
    end
    available[spec.name] << { :spec => spec, :source => source } unless duplicate
  end

  def activate(selected)
    datadog = selected['datadog'] && selected['datadog'][:spec]
    raise ResolutionError.new('The injection package does not resolve a datadog gem') unless datadog

    added_paths = []
    previous_specs = {}

    selected.each_value do |candidate|
      next if candidate[:source] == :loaded

      spec = candidate[:spec]
      add_to_load_path(spec, added_paths)

      previous_specs[spec.name] = Gem.loaded_specs[spec.name]
      Gem.loaded_specs[spec.name] = spec
    end

    begin
      require File.join(datadog.full_gem_path, 'lib', 'datadog', 'single_step_instrument')

      unless defined?(::Datadog::SingleStepInstrument::LOADED)
        raise LoadError.new('Datadog single-step instrumentation did not load')
      end
    rescue LoadError
      rollback(added_paths, previous_specs)
      raise
    rescue ::LoadError, StandardError => e
      rollback(added_paths, previous_specs)
      raise LoadError.new('Failed to load Datadog directly', e)
    end
  end

  def add_to_load_path(spec, added_paths)
    paths = spec.full_require_paths.reject { |path| $LOAD_PATH.include?(path) }
    return if paths.empty?

    insert_index = Gem.load_path_insert_index
    if insert_index
      $LOAD_PATH.insert(insert_index, *paths)
    else
      $LOAD_PATH.unshift(*paths)
    end
    added_paths.concat(paths)
  end

  def rollback(added_paths, previous_specs)
    added_paths.each { |path| $LOAD_PATH.delete(path) }

    previous_specs.each do |name, spec|
      if spec
        Gem.loaded_specs[name] = spec
      else
        Gem.loaded_specs.delete(name)
      end
    end
  end
end
