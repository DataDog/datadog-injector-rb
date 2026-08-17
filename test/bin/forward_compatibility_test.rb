forward_compatibility_path = File.expand_path('../../src/mod/forward_compatibility.rb', __dir__)
forward_compatibility = Module.new
forward_compatibility.module_eval(File.read(forward_compatibility_path), forward_compatibility_path)

def forward_compatibility_status(ruby_version, rubygems_version, bundler_version, simulate_version=nil)
  {
    :ruby => { :version => ruby_version },
    :bundler => {
      :rubygems => rubygems_version,
      :version => bundler_version,
      :simulate_version => simulate_version,
    },
  }
end

raise 'Ruby 4.0 should keep the established injector' if forward_compatibility.required?(forward_compatibility_status('4.0.6', '4.0.17', '4.0.17'))
raise 'RubyGems 5 should use direct loading' unless forward_compatibility.rubygems?(forward_compatibility_status('4.0.6', '5.0.0', '4.0.17'))
raise 'Bundler 5 should use direct loading' unless forward_compatibility.bundler?(forward_compatibility_status('4.0.6', '4.0.17', '5.0.0'))
raise 'simulated Bundler 5 should use direct loading' unless forward_compatibility.simulated_bundler?(forward_compatibility_status('4.0.6', '4.0.17', '4.0.17', '5.0'))
raise 'Ruby 5 alone must not expand SDK support' if forward_compatibility.required?(forward_compatibility_status('5.0.0', '4.0.17', '4.0.17'))
