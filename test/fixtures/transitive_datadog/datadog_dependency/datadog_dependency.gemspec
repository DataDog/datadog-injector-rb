Gem::Specification.new do |spec|
  spec.name = 'datadog_dependency'
  spec.version = '1.0.0'
  spec.summary = 'Transitive Datadog dependency for injector tests'
  spec.authors = ['Datadog']
  spec.files = ['lib/datadog_dependency.rb']

  spec.add_dependency 'datadog', '= 2.36.0'
end
