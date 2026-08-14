Gem::Specification.new do |spec|
  spec.name = 'fixture-transitive'
  spec.version = '1.0.0'
  spec.summary = 'Fixture with a transitive dependency shared with the injector package'
  spec.authors = ['Datadog']
  spec.files = []

  spec.add_runtime_dependency 'ffi', '= 1.17.0'
end
