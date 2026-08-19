direct_path = File.expand_path('../../src/mod/direct.rb', __dir__)
direct_bundler = Module.new
direct_resolver = Module.new
direct_resolver.const_set(:Conflict, Class.new(StandardError))

class << direct_bundler
  def require!; end
end

direct = Module.new
direct.define_singleton_method(:import) do |name|
  name == 'bundler' ? direct_bundler : direct_resolver
end
direct.module_eval(File.read(direct_path), direct_path)

%w[bundle bundler bundle3.1 bundler3.1 bundle3.1.2].each do |name|
  context = { :process => { :name => "/usr/bin/#{name}" } }
  raise "#{name} should be detected as a Bundler CLI" unless direct.send(:bundler_cli?, context)
end

%w[bundle-install rebundler application].each do |name|
  context = { :process => { :name => "/usr/bin/#{name}" } }
  raise "#{name} should not be detected as a Bundler CLI" if direct.send(:bundler_cli?, context)
end

direct.define_singleton_method(:require) { |_path| raise SystemExit.new(17) }
begin
  direct.send(:setup_bundle)
  raise 'Bundler setup SystemExit was not converted to SetupError'
rescue direct.const_get(:SetupError) => e
  raise 'SetupError did not retain the SystemExit cause' unless e.cause.is_a?(SystemExit) && e.cause.status == 17
end
