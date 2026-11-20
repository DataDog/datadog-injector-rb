raise 'Nested Ruby could not load the bundle' unless system(RbConfig.ruby, '-e', "require 'rack'; require 'datadog'")

Bundler.with_unbundled_env do
  rubyopt = ENV.fetch('RUBYOPT')
  raise "Original injector option not restored: #{rubyopt.inspect}" unless rubyopt == ENV.fetch('EXPECTED_RUBYOPT')
  raise 'Bundler setup leaked into the unbundled environment' if ENV['BUNDLER_SETUP']
end
