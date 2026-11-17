# ruby-version-min: 1.8.7

require File.expand_path('../support/modules', File.dirname(__FILE__))

module ErrorTypesTest
  Context = TestModules.import('context')
  Report = TestModules.import('report')
  Injector = TestModules.import('injector')

  class ApplicationError < StandardError
    attr_accessor :cause
  end

  def self.check_failure(exception, type)
    result = Injector.send(:failure, 'bundler.inject', exception)
    TestModules.assert_equal(type, result.last)
    # The type is a primitive value that can cross the same pipe as the reason.
    TestModules.assert_equal(result, Marshal.load(Marshal.dump(result)))
  end

  def self.run
    exception = ApplicationError.new('private application details')
    exception.cause = Errno::ENOENT.new('private path')
    TestModules.assert_equal('ErrorTypesTest::ApplicationError', Report.error_type(exception))
    TestModules.assert_equal('exc.injector.missing_file', Report.reason('exc.injector', exception))
    TestModules.assert_equal('NoMethodError', Report.error_type(NoMethodError.new))
    TestModules.assert_equal('unknown', Report.error_type(nil))
    TestModules.assert_equal('unknown', Report.error_type(Class.new(StandardError).new))
    anonymous = Module.new
    anonymous.const_set(:Failure, Class.new(StandardError))
    TestModules.assert_equal('unknown', Report.error_type(anonymous.const_get(:Failure).new))

    wrapper = Injector::Patch::Injector::InjectionError
    check_failure(exception, 'ErrorTypesTest::ApplicationError')
    check_failure(wrapper.new('outer wrapper', wrapper.new('inner wrapper', exception)),
      'ErrorTypesTest::ApplicationError')
    check_failure(wrapper.new('no cause'), 'unknown')
    cycle = wrapper.new('cycle')
    cycle.instance_variable_set(:@cause, cycle)
    check_failure(cycle, 'unknown')
    deep = exception
    (Context::IsolatedError::MAX_CHAIN_LENGTH + 1).times { deep = wrapper.new('nested', deep) }
    check_failure(deep, 'unknown')

    if Process.respond_to?(:fork)
      boxed = begin
        Context.isolate do
          Object.const_set(:ChildOnlyErrorTypes, Module.new)
          ChildOnlyErrorTypes.const_set(:Failure, Class.new(StandardError))
          raise ChildOnlyErrorTypes::Failure, 'private child details'
        end
      rescue Context::IsolatedError => e
        e
      end
      TestModules.assert_equal(false, Object.const_defined?(:ChildOnlyErrorTypes))
      TestModules.assert_equal('ChildOnlyErrorTypes::Failure', Report.error_type(boxed))
      check_failure(wrapper.new('wrapper around boxed failure', boxed), 'ChildOnlyErrorTypes::Failure')

      boxed = begin
        Context.isolate { raise Class.new(StandardError), 'anonymous child failure' }
      rescue Context::IsolatedError => e
        e
      end
      TestModules.assert_equal('unknown', Report.error_type(boxed))
    end

    puts 'Error types: named classes, boxing, wrapper selection, and stable fallbacks passed'
  end
end

ErrorTypesTest.run
