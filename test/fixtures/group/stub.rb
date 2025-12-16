stub = File.basename(File.dirname(File.expand_path(__FILE__)))

puts "stub:#{stub} start"

require 'rubygems' unless defined?(Gem)

puts "stub:#{stub} GEM_PATH:#{ENV['GEM_PATH'].inspect}"
puts "stub:#{stub} Gem.path:#{Gem.path.inspect}"
puts "stub:#{stub} deps:#{Gem.loaded_specs.map { |name, spec| [name, spec.version.to_s] }}"

if Gem.loaded_specs['datadog']
  require 'datadog'
  puts "stub:#{stub} datadog:#{!!defined?(Datadog)}"
end
