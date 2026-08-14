Gem::Specification.new do |spec|
  spec.name = 'fixture-conflict'
  spec.version = '1.0.0'
  spec.summary = 'Fixture with a transitive dependency conflicting with the injector package'
  spec.authors = ['Datadog']
  spec.files = []

  spec.add_runtime_dependency 'datadog-ruby_core_source', '= 3.4.0'
end
