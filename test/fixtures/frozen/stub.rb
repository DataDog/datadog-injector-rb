stub = File.basename(File.dirname(File.expand_path(__FILE__)))

puts "stub:#{stub} start"

at_exit { puts "stub:#{stub} exit" }

require 'rubygems' unless defined?(Gem)

puts "stub:#{stub} GEM_PATH:#{ENV['GEM_PATH'].inspect}"
puts "stub:#{stub} Gem.path:#{Gem.path.inspect}"
puts "stub:#{stub} deps:#{Gem.loaded_specs.map { |name, spec| [name, spec.version.to_s] }.inspect}"

if Gem.loaded_specs['datadog']
  require 'datadog'
  puts "stub:#{stub} datadog:#{!!defined?(Datadog)}"
end

if ENV['DD_TEST_EXPECT_READ_ONLY_INJECTION'] == 'true'
  raise 'Read-only injection fixture unexpectedly has a writable application directory' if File.writable?(Dir.pwd)

  unless defined?(Datadog::SingleStepInstrument::LOADED)
    raise 'Datadog was not loaded on a read-only application directory'
  end
end
