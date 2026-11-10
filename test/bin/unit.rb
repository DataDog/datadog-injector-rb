require_relative 'test'

engine, version = ARGV
raise ArgumentError, 'Expected engine and version' unless engine && version

Dir[File.join(INJECTION_DIR, 'test', 'unit', '*.rb')].sort.each do |path|
  _, status = run 'ruby', path, engine: engine, version: version,
    network: false, isolated: true, title: File.basename(path)
  exit 1 unless status.success?
end
