resolver_path = File.expand_path('../../src/mod/resolver.rb', __dir__)
resolver_module = Module.new
resolver_module.module_eval(File.read(resolver_path), resolver_path)
resolver_class = resolver_module.const_get(:Resolver)
conflict_class = resolver_module.const_get(:Conflict)

def resolver_spec(name, version, dependencies = [])
  Gem::Specification.new do |spec|
    spec.name = name
    spec.version = version
    spec.summary = name
    spec.authors = ['test']
    spec.files = []
    dependencies.each { |dependency| spec.add_runtime_dependency(*dependency) }
  end
end

def resolver_candidate(spec, source = :package)
  { :spec => spec, :source => source }
end

root = resolver_spec('root', '1.0', [['adapter', '>= 1']])
adapter_2 = resolver_spec('adapter', '2.0', [['core', '>= 2']])
adapter_1 = resolver_spec('adapter', '1.0', [['core', '< 2']])
core_1 = resolver_spec('core', '1.0')
available = {
  'root' => [resolver_candidate(root)],
  'adapter' => [resolver_candidate(adapter_1), resolver_candidate(adapter_2)],
  'core' => [resolver_candidate(core_1)],
}

selected = resolver_class.new(available, {}).resolve(Gem::Dependency.new('root'))
raise 'resolver did not backtrack to adapter 1.0' unless selected['adapter'][:spec].version == Gem::Version.new('1.0')

locked_adapter = resolver_spec('adapter', '1.25', [['core', '< 2']])
available['adapter'] << resolver_candidate(locked_adapter, :package_locked)
selected = resolver_class.new(available, {}).resolve(Gem::Dependency.new('root'))
raise 'resolver did not prefer the package lockfile candidate' unless selected['adapter'][:spec] == locked_adapter

application_adapter = resolver_spec('adapter', '1.5', [['core', '< 2']])
available['adapter'] << resolver_candidate(application_adapter, :application)
selected = resolver_class.new(available, {}).resolve(Gem::Dependency.new('root'))
raise 'resolver did not prefer the application candidate' unless selected['adapter'][:spec] == application_adapter

fallback_root = resolver_spec('fallback-root', '1.0', [['choice', '>= 1']])
application_choice = resolver_spec('choice', '1.0', [['missing', '>= 1']])
package_choice = resolver_spec('choice', '2.0')
fallback_available = {
  'fallback-root' => [resolver_candidate(fallback_root)],
  'choice' => [resolver_candidate(application_choice, :application), resolver_candidate(package_choice)],
}
selected = resolver_class.new(fallback_available, {}).resolve(Gem::Dependency.new('fallback-root'))
raise 'resolver did not backtrack from an unsatisfiable application candidate' unless selected['choice'][:spec] == package_choice

runtime_root = resolver_spec('runtime-root', '1.0', [['runtime-choice', '>= 1']])
runtime_bad = resolver_spec('runtime-choice', '2.0')
runtime_bad.required_ruby_version = Gem::Requirement.new('> 999')
runtime_good = resolver_spec('runtime-choice', '1.0')
runtime_available = {
  'runtime-root' => [resolver_candidate(runtime_root)],
  'runtime-choice' => [resolver_candidate(runtime_bad), resolver_candidate(runtime_good)],
}
selected = resolver_class.new(runtime_available, {}).resolve(Gem::Dependency.new('runtime-root'))
raise 'resolver did not skip a runtime-incompatible candidate' unless selected['runtime-choice'][:spec] == runtime_good

platform_root = resolver_spec('platform-root', '1.0', [['platform-choice', '>= 1']])
platform_bad = resolver_spec('platform-choice', '2.0')
platform_bad.platform = Gem::Platform.new('definitely-not-local-platform')
platform_good = resolver_spec('platform-choice', '1.0')
platform_available = {
  'platform-root' => [resolver_candidate(platform_root)],
  'platform-choice' => [resolver_candidate(platform_bad), resolver_candidate(platform_good)],
}
selected = resolver_class.new(platform_available, {}).resolve(Gem::Dependency.new('platform-root'))
raise 'resolver did not skip a platform-incompatible candidate' unless selected['platform-choice'][:spec] == platform_good

loaded_core = resolver_spec('core', '1.5')
loaded_available = available.merge('core' => [resolver_candidate(resolver_spec('core', '1.8'))])
selected = resolver_class.new(loaded_available, { 'core' => loaded_core }).resolve(Gem::Dependency.new('root'))
raise 'resolver did not preserve a compatible activated gem' unless selected['core'][:source] == :loaded

begin
  conflict_root = resolver_spec('conflict-root', '1.0', [['core', '< 2']])
  conflict_available = available.merge('conflict-root' => [resolver_candidate(conflict_root)])
  resolver_class.new(conflict_available, { 'core' => resolver_spec('core', '2.0') }).resolve(Gem::Dependency.new('conflict-root'))
  raise 'resolver accepted an incompatible activated gem'
rescue conflict_class => e
  raise 'resolver conflict did not identify activated gem' unless e.message.include?('already activated')
end
