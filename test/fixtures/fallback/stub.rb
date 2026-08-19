stub = File.basename(File.dirname(File.expand_path(__FILE__)))

puts "stub:#{stub} start"

at_exit { puts "stub:#{stub} exit" }

unless ENV['DD_INTERNAL_RUBY_INJECTOR_DIRECT'] == 'true'
  raise 'Normal injection failure did not enable direct fallback'
end

unless defined?(Datadog::SingleStepInstrument::LOADED)
  raise 'Datadog was not loaded by direct fallback'
end

unless Gem.loaded_specs['ffi'] && Gem.loaded_specs['ffi'].version.to_s == '1.17.0'
  raise 'Direct fallback replaced the application dependency selection'
end

if ENV['BUNDLE_GEMFILE'] && File.basename(ENV['BUNDLE_GEMFILE']) == 'datadog.gemfile'
  raise 'Direct fallback activated the failed generated Gemfile'
end

puts "stub:#{stub} datadog:true"
