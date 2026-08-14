# ruby-version-min: 1.8.7

BUNDLER = import 'bundler'

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

    selected, packaged = resolve(package[:gem_home], package[:lockfile])
    activate(selected, packaged)

    true
  end

  private

  def bundler_cli?(context)
    name = context[:process][:name]
    name && ['bundle', 'bundler'].include?(File.basename(name))
  end

  def setup_bundle
    BUNDLER.send(:require!)

    begin
      require 'bundler/setup'
    rescue StandardError => e
      raise SetupError.new('Failed to activate the application bundle', e)
    end
  end

  def resolve(gem_home, lockfile)
    begin
      locked = Bundler::LockfileParser.new(Bundler.read_file(lockfile))
      available = load_package_specs(gem_home, locked.specs)
      selected = {}
      packaged = {}
      datadog = locked.dependencies['datadog']

      unless datadog
        raise ResolutionError.new('The injection package does not declare a datadog dependency')
      end

      resolve_dependency(datadog, 'injection package', available, selected, packaged)

      [selected, packaged]
    rescue DirectError
      raise
    rescue StandardError => e
      raise ResolutionError.new('Failed to resolve direct injection dependencies', e)
    end
  end

  def load_package_specs(gem_home, locked_specs)
    locked = {}
    locked_specs.each { |spec| locked[[spec.name, spec.version.to_s]] = true }

    available = {}
    pattern = File.join(gem_home, 'specifications', '*.gemspec')

    Dir[pattern].sort.each do |path|
      spec = Gem::Specification.load(path)
      next unless spec
      next unless locked[[spec.name, spec.version.to_s]]

      available[spec.name] ||= []
      available[spec.name] << spec
    end

    available
  end

  def resolve_dependency(dependency, parent, available, selected, packaged)
    if (spec = selected[dependency.name])
      validate_requirement(dependency, parent, spec)
      return spec
    end

    if (spec = Gem.loaded_specs[dependency.name])
      validate_requirement(dependency, parent, spec)
      selected[dependency.name] = spec
      return spec
    end

    candidates = available[dependency.name] || []
    spec = candidates.find { |candidate| dependency.requirement.satisfied_by?(candidate.version) }

    unless spec
      raise ResolutionError.new("#{parent} requires #{dependency}, but the injection package does not provide it")
    end

    validate_runtime(spec)

    selected[dependency.name] = spec
    packaged[dependency.name] = spec

    spec.runtime_dependencies.each do |child|
      resolve_dependency(child, spec.full_name, available, selected, packaged)
    end

    spec
  end

  def validate_requirement(dependency, parent, spec)
    return if dependency.requirement.satisfied_by?(spec.version)

    raise ResolutionError.new("#{parent} requires #{dependency}, but #{spec.full_name} is already selected")
  end

  def validate_runtime(spec)
    unless spec.required_ruby_version.satisfied_by?(Gem.ruby_version)
      raise ResolutionError.new("#{spec.full_name} does not support Ruby #{Gem.ruby_version}")
    end

    return if spec.required_rubygems_version.satisfied_by?(Gem::Version.new(Gem::VERSION))

    raise ResolutionError.new("#{spec.full_name} does not support RubyGems #{Gem::VERSION}")
  end

  def activate(selected, packaged)
    datadog = selected['datadog']
    raise ResolutionError.new('The injection package does not resolve a datadog gem') unless datadog

    added_paths = []
    previous_specs = {}

    packaged.each_value do |spec|
      spec.full_require_paths.each do |path|
        next if $LOAD_PATH.include?(path)

        $LOAD_PATH << path
        added_paths << path
      end

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
