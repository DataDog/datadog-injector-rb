stub = File.basename(File.dirname(File.expand_path(__FILE__)))

puts "stub:#{stub} start"

at_exit { puts "stub:#{stub} exit" }

if File.writable?(Dir.pwd)
  raise 'Direct injection fixture unexpectedly has a writable application directory'
end

unless defined?(Datadog::SingleStepInstrument::LOADED)
  raise 'Datadog was not loaded by direct injection'
end

if (logger = Gem.loaded_specs['logger'])
  loaded_logger = $LOADED_FEATURES.find { |path| File.basename(path) == 'logger.rb' }
  unless loaded_logger && loaded_logger.index(logger.full_gem_path) == 0
    raise "Direct injection loaded logger outside the selected gem: #{loaded_logger.inspect}"
  end
end

if ENV['DD_INTERNAL_RUBY_INJECTOR_PATCH']
  raise 'Direct injection unexpectedly enabled the Bundler patch'
end

if ENV['BUNDLE_GEMFILE'] && File.basename(ENV['BUNDLE_GEMFILE']) == 'datadog.gemfile'
  raise 'Direct injection unexpectedly replaced the application Gemfile'
end

puts "stub:#{stub} datadog:true"
