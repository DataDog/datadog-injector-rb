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

# When in-memory gemfile/lockfile content is available (set by the injector
# via env vars and intercepted by Bundler.read_file via patch_reads!),
# compare disk vs in-memory content and persist to files for test verification.
if defined?(Bundler) && ENV['DD_INTERNAL_RUBY_INJECTOR_GEMFILE_CONTENT']
  gemfile_path = Bundler.default_gemfile.to_s
  lockfile_path = Bundler.default_lockfile.to_s

  gemfile_disk = File.read(gemfile_path) rescue nil
  gemfile_mem = Bundler.read_file(gemfile_path) rescue nil

  lockfile_disk = File.read(lockfile_path) rescue nil
  lockfile_mem = Bundler.read_file(lockfile_path) rescue nil

  puts "stub:#{stub} gemfile_patched:#{gemfile_disk != gemfile_mem}"
  puts "stub:#{stub} lockfile_patched:#{lockfile_disk != lockfile_mem}"

  # Persist in-memory content to datadog.gemfile / datadog.gemfile.lock
  # so that test examples can examine the injected content on the filesystem.
  dir = File.dirname(gemfile_path)
  File.write(File.join(dir, 'datadog.gemfile'), gemfile_mem) if gemfile_mem
  File.write(File.join(dir, 'datadog.gemfile.lock'), lockfile_mem) if lockfile_mem
end
