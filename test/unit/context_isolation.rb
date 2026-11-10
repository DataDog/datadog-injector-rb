# ruby-version-min: 1.8.7

require File.expand_path('../support/modules', File.dirname(__FILE__))

module ContextIsolationTest
  Context = TestModules.import('context')

  def self.error(&block)
    begin
      Context.isolate(&block)
    rescue Context::IsolatedError => e
      return e
    end
    raise 'Expected an isolated exception'
  end

  def self.run
    [nil, false, true, :error, [:error, { :exceptions => [] }], { :nested => ['value', 1] }].each do |value|
      TestModules.assert_equal(value, Context.isolate { value })
    end

    unless Process.respond_to?(:fork)
      original = RuntimeError.new('no fork')
      caught = false
      begin
        Context.isolate { raise original }
      rescue RuntimeError => e
        raise 'Non-forking execution changed the exception' unless e.equal?(original)
        caught = true
      end
      TestModules.assert_equal(true, caught)
      puts 'Context isolation: non-forking behaviour passed'
      return
    end

    boxed = error do
      # Neither the original class, its superclass, nor its cause exists in the parent.
      Object.const_set(:ChildOnlyErrors, Module.new)
      ChildOnlyErrors.const_set(:Base, Class.new(StandardError) { attr_accessor :cause })
      ChildOnlyErrors.const_set(:Failure, Class.new(ChildOnlyErrors::Base))
      ChildOnlyErrors.const_set(:Text, Class.new(String))
      cause = ChildOnlyErrors::Base.new('underlying failure')
      cause.set_backtrace(['cause.rb:2'])
      original = ChildOnlyErrors::Failure.new('original failure')
      original.cause = cause
      original.instance_variable_set(:@unmarshallable, proc {})
      def original.message
        text = ChildOnlyErrors::Text.new('original failure')
        text.instance_variable_set(:@unmarshallable, proc {})
        text
      end
      original.set_backtrace(['original.rb:1'])
      raise original
    end
    TestModules.assert_equal(false, Object.const_defined?(:ChildOnlyErrors))
    TestModules.assert_equal('ChildOnlyErrors::Failure', boxed.original_class)
    TestModules.assert_equal(['ChildOnlyErrors::Failure', 'ChildOnlyErrors::Base'], boxed.original_ancestors.take(2))
    TestModules.assert_equal('original failure', boxed.original_message)
    TestModules.assert_equal('ChildOnlyErrors::Failure: original failure', boxed.message)
    TestModules.assert_equal(['original.rb:1'], boxed.backtrace)
    TestModules.assert_equal(1, boxed.causes.length)
    TestModules.assert_equal('ChildOnlyErrors::Base', boxed.causes.first[:class_name])
    TestModules.assert_equal('underlying failure', boxed.causes.first[:message])
    TestModules.assert_equal(['cause.rb:2'], boxed.causes.first[:backtrace])
    TestModules.assert_equal('ChildOnlyErrors::Base', boxed.causes.first[:ancestors].first)
    TestModules.assert_equal(false, boxed.causes_truncated)
    TestModules.assert_equal(nil, boxed.cause) if boxed.respond_to?(:cause)

    [LoadError, SyntaxError].each do |type|
      boxed = error { raise type, 'load failed' }
      TestModules.assert_equal(type.name, boxed.original_class)
      TestModules.assert_equal([], boxed.causes)
    end

    boxed = error do
      exception = StandardError.new('cycle')
      def exception.cause; self; end
      raise exception
    end
    TestModules.assert_equal([], boxed.causes)
    TestModules.assert_equal(true, boxed.causes_truncated)

    boxed = error do
      type = Class.new(StandardError) { attr_accessor :cause }
      exception = nil
      (Context::IsolatedError::MAX_CHAIN_LENGTH + 1).times do
        parent = type.new('nested')
        parent.cause = exception
        exception = parent
      end
      raise exception
    end
    TestModules.assert_equal(Context::IsolatedError::MAX_CHAIN_LENGTH - 1, boxed.causes.length)
    TestModules.assert_equal(true, boxed.causes_truncated)

    puts 'Context isolation: result envelopes, child-only exceptions, and bounded causes passed'
  end
end

ContextIsolationTest.run
