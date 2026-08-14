stub = File.basename(File.dirname(File.expand_path(__FILE__)))

puts "stub:#{stub} start"

at_exit { puts "stub:#{stub} exit" }

require 'rubygems' unless defined?(Gem)

puts "stub:#{stub} GEM_PATH:#{ENV['GEM_PATH'].inspect}"
puts "stub:#{stub} Gem.path:#{Gem.path.inspect}"
puts "stub:#{stub} deps:#{Gem.loaded_specs.map { |name, spec| [name, spec.version.to_s] }.inspect}"

if ENV['DD_INTERNAL_RUBY_INJECTOR_DIRECT'] == 'true' && Gem.loaded_specs['ffi'].version.to_s != '1.17.0'
  raise 'Direct injection did not preserve the application ffi version'
end

if Gem.loaded_specs['datadog']
  require 'datadog'
  puts "stub:#{stub} datadog:#{!!defined?(Datadog)}"
end
