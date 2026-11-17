# ruby-version-min: 1.8.7

require File.expand_path('../support/modules', File.dirname(__FILE__))

module ErrorTelemetryTest
  Context = TestModules.import('context')
  Guard = TestModules.import('guard')
  Injector = TestModules.import('injector')
  Telemetry = TestModules.import('telemetry')

  class << self
    attr_accessor :stage, :events
  end

  def Context.eval
    raise Errno::EACCES, 'private context details' if ErrorTelemetryTest.stage == :context
    {}
  end

  def Guard.call(context)
    raise NoMethodError, 'unexpected guard failure' if ErrorTelemetryTest.stage == :guard
    nil
  end

  def Injector.call(context)
    raise Errno::ENOENT, 'private injection details' if ErrorTelemetryTest.stage == :injector
    [nil, 'bundler.inject.resolve.injected.missing_gem']
  end

  def Telemetry.emit(points, options = {})
    ErrorTelemetryTest.events << [points, options]
  end

  def self.run
    previous = ENV.delete('DD_INTERNAL_RUBY_INJECTOR')
    [
      [:context, 'exc.context.permission_denied', 'incompatible_environment'],
      [:guard, 'exc.guard.unknown', 'internal_error'],
      [:injector, 'exc.injector.missing_file', 'incompatible_environment'],
      [:reported, 'bundler.inject.resolve.injected.missing_gem', 'incompatible_dependency'],
    ].each do |stage, reason, result_class|
      self.stage = stage
      self.events = []
      main = Module.new do
        def self.import(name); TestModules.import(name); end
      end
      path = File.expand_path('../../src/mod/main.rb', File.dirname(__FILE__))
      main.module_eval(File.read(path), path)

      TestModules.assert_equal(2, events.length)
      TestModules.assert_equal('library_entrypoint.start', events.first[0].first[:name])
      TestModules.assert_equal([{
        :name => 'library_entrypoint.error', :tags => ["reason:#{reason}"],
      }], events.last[0])
      result = events.last[1][:result]
      TestModules.assert_equal('error', result[:result])
      TestModules.assert_equal(result_class, result[:result_class])
      TestModules.assert_equal(false, result[:result_reason].include?('private'))
    end
    puts 'Error telemetry: one conclusion, stage-specific reasons, and result metadata passed'
  ensure
    ENV['DD_INTERNAL_RUBY_INJECTOR'] = previous if previous
  end
end

ErrorTelemetryTest.run
