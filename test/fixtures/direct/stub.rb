stub = File.basename(File.dirname(File.expand_path(__FILE__)))

puts "stub:#{stub} start"

at_exit { puts "stub:#{stub} exit" }

if File.writable?(Dir.pwd)
  raise 'Direct injection fixture unexpectedly has a writable application directory'
end

unless defined?(Datadog::SingleStepInstrument::LOADED)
  raise 'Datadog was not loaded by direct injection'
end

if ENV['DD_INTERNAL_RUBY_INJECTOR_PATCH']
  raise 'Direct injection unexpectedly enabled the Bundler patch'
end

if ENV['BUNDLE_GEMFILE'] && File.basename(ENV['BUNDLE_GEMFILE']) == 'datadog.gemfile'
  raise 'Direct injection unexpectedly replaced the application Gemfile'
end

puts "stub:#{stub} datadog:true"
