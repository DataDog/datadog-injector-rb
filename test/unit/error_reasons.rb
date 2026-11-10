# ruby-version-min: 1.8.7

require File.expand_path('../support/modules', File.dirname(__FILE__))

module ErrorReasonsTest
  Context = TestModules.import('context')
  Report = TestModules.import('report')
  Injector = TestModules.import('injector')

  def self.run
    [
      [Errno::EACCES.new, 'permission_denied', 'incompatible_environment'],
      [Errno::EPERM.new, 'permission_denied', 'incompatible_environment'],
      [Errno::EROFS.new, 'read_only', 'incompatible_environment'],
      [Errno::ENOENT.new, 'missing_file', 'incompatible_environment'],
      [Errno::ENOSPC.new, 'no_space', 'incompatible_environment'],
      [LoadError.new, 'load_error', 'incompatible_component'],
      [SyntaxError.new, 'syntax_error', 'incompatible_component'],
      [NoMethodError.new('private application details'), 'unknown', 'internal_error'],
    ].each do |exception, kind, result_class|
      reason = Report.reason('exc.context', exception)
      TestModules.assert_equal("exc.context.#{kind}", reason)
      TestModules.assert_equal(result_class, Report.errored(reason)[:result_class])
      TestModules.assert_equal(false, Report.errored(reason)[:result_reason].include?('private application details'))
    end

    wrapper = Injector::Patch::Injector::GemfileWriteError.new('append failed', Errno::EROFS.new)
    TestModules.assert_equal('bundler.inject.gemfile.write.read_only', Report.reason('bundler.inject.gemfile.write', wrapper))
    TestModules.assert_equal(['fs.write.permission_denied', 'write failed', nil],
      Injector::Err.new('fs.write.permission_denied', IOError.new('write failed')).to_a)
    TestModules.assert_equal('incompatible_component', Report.class_of('bundler.version'))
    TestModules.assert_equal('incompatible_dependency', Report.class_of('bundler.inject'))

    if Process.respond_to?(:fork)
      boxed = begin
        Context.isolate do
          Object.const_set(:Bundler, Module.new)
          Bundler.const_set(:GemNotFound, Class.new(StandardError))
          Bundler.const_set(:MissingVariant, Class.new(Bundler::GemNotFound))
          raise Bundler::MissingVariant, 'application-specific gem name'
        end
      rescue Context::IsolatedError => e
        e
      end
      TestModules.assert_equal(false, Object.const_defined?(:Bundler))
      TestModules.assert_equal('exc.context.missing_gem', Report.reason('exc.context', boxed))

      boxed = begin
        Context.isolate do
          Object.const_set(:Bundler, Module.new)
          Bundler.const_set(:HTTPError, Class.new(StandardError))
          original = StandardError.new('wrapper')
          original.instance_variable_set(:@underlying, Bundler::HTTPError.new('private URL'))
          def original.cause; @underlying; end
          raise original
        end
      rescue Context::IsolatedError => e
        e
      end
      TestModules.assert_equal('exc.injector.remote_source', Report.reason('exc.injector', boxed))
    end

    puts 'Error reasons: bounded categories, metadata, wrapping, and child-only inheritance passed'
  end
end

ErrorReasonsTest.run
