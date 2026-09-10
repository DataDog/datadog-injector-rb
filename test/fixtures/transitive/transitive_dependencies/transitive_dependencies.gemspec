Gem::Specification.new do |spec|
  spec.name = 'transitive_dependencies'
  spec.version = '1.0.0'
  spec.summary = 'Transitive application dependencies for injector tests'
  spec.authors = ['Datadog']
  spec.files = ['lib/transitive_dependencies.rb']

  spec.add_dependency 'ffi', '= 1.17.0'
  spec.add_dependency 'msgpack', '= 1.8.4'
end
