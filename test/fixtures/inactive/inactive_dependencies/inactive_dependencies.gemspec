Gem::Specification.new do |spec|
  spec.name = 'inactive_dependencies'
  spec.version = '1.0.0'
  spec.summary = 'Inactive transitive dependencies for injector tests'
  spec.authors = ['Datadog']
  spec.files = ['lib/inactive_dependencies.rb']

  spec.add_dependency 'did_you_mean', '= 1.3.0'
end
