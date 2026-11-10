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
    isolate { raise Errno::EACCES, 'private context details' } if ErrorTelemetryTest.stage == :context
    {}
  end

  def Guard.call(context)
    raise NoMethodError, 'unexpected guard failure' if ErrorTelemetryTest.stage == :guard
    return [{ :reason => 'bundler.unbundled' }] if ErrorTelemetryTest.stage == :abort
    nil
  end

  def Injector.call(context)
    raise Errno::ENOENT, 'private injection details' if ErrorTelemetryTest.stage == :injector
    return [true, nil] if ErrorTelemetryTest.stage == :complete
    [nil, 'bundler.inject.resolve.injected.missing_gem', 'Bundler::GemNotFound']
  end

  def Telemetry.emit(points, options = {})
    ErrorTelemetryTest.events << [points, options]
  end

  def self.run
    previous = ENV.delete('DD_INTERNAL_RUBY_INJECTOR')
    [
      [:context, 'exc.context.permission_denied', 'incompatible_environment', 'Errno::EACCES'],
      [:guard, 'exc.guard.unknown', 'internal_error', 'NoMethodError'],
      [:injector, 'exc.injector.missing_file', 'incompatible_environment', 'Errno::ENOENT'],
      [:reported, 'bundler.inject.resolve.injected.missing_gem', 'incompatible_dependency', 'Bundler::GemNotFound'],
    ].each do |stage, reason, result_class, type|
      evaluate(stage)

      TestModules.assert_equal(2, events.length)
      TestModules.assert_equal('library_entrypoint.start', events.first[0].first[:name])
      TestModules.assert_equal([{
        :name => 'library_entrypoint.error', :tags => ["reason:#{reason}", "error_type:#{type}"],
      }], events.last[0])
      result = events.last[1][:result]
      TestModules.assert_equal('error', result[:result])
      TestModules.assert_equal(result_class, result[:result_class])
      TestModules.assert_equal(false, result[:result_reason].include?('private'))
    end

    [:abort, :complete].each do |stage|
      evaluate(stage)
      TestModules.assert_equal(2, events.length)
      TestModules.assert_equal("library_entrypoint.#{stage}", events.last[0].first[:name])
      events.each do |points, _|
        points.each do |point|
          TestModules.assert_equal([], (point[:tags] || []).grep(/^error_type:/))
        end
      end
    end
    puts 'Error telemetry: one conclusion, stage-specific reasons, and result metadata passed'
  ensure
    ENV['DD_INTERNAL_RUBY_INJECTOR'] = previous if previous
  end

  def self.evaluate(stage)
    self.stage = stage
    self.events = []
    main = Module.new do
      def self.import(name); TestModules.import(name); end
    end
    path = File.expand_path('../../src/mod/main.rb', File.dirname(__FILE__))
    main.module_eval(File.read(path), path)
  end
end

ErrorTelemetryTest.run
