forward_guard_path = File.expand_path('../../src/mod/guard.rb', __dir__)
forward_compatibility_path = File.expand_path('../../src/mod/forward_compatibility.rb', __dir__)
forward_compatibility_for_guard = Module.new
forward_compatibility_for_guard.module_eval(File.read(forward_compatibility_path), forward_compatibility_path)
forward_guard = Module.new
forward_guard.define_singleton_method(:import) do |name|
  raise "unexpected import: #{name}" unless name == 'forward_compatibility'

  forward_compatibility_for_guard
end
forward_guard.module_eval(File.read(forward_guard_path), forward_guard_path)

def forward_guard_status(ruby_version, rubygems_version, bundler_version, fallback, locked=true)
  {
    :inject => {
      :ruby => {
        :direct => false,
        :direct_fallback => fallback,
        :force => {},
      },
    },
    :ruby => {
      :version => ruby_version,
      :prerelease => false,
      :engine => 'ruby',
    },
    :runtime => { :fork => true },
    :bundler => {
      :rubygems => rubygems_version,
      :version => bundler_version,
      :simulate_version => nil,
      :bundled => true,
      :locked => locked,
      :settings => { :force_ruby_platform => false },
    },
    :fs => { :writable => true },
  }
end

ruby_5_result = forward_guard.call(forward_guard_status('5.0.0', '4.0.17', '4.0.17', true))
unless ruby_5_result && ruby_5_result.any? { |entry| entry[:reason] == 'runtime.version' }
  raise 'direct component compatibility must not expand Ruby SDK support'
end

bundler_5_result = forward_guard.call(forward_guard_status('4.0.6', '4.0.17', '5.0.0', true, false))
raise 'Bundler 5 should be eligible for direct loading' if bundler_5_result

bundler_5_disabled = forward_guard.call(forward_guard_status('4.0.6', '4.0.17', '5.0.0', false))
unless bundler_5_disabled && bundler_5_disabled.any? { |entry| entry[:reason] == 'bundler.version' }
  raise 'the direct loading kill switch should retain the Bundler 5 guard'
end
