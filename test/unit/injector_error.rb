# ruby-version-min: 1.8.7

module InjectorErrorTest
  Injector = Module.new do
    # Reporting does not use the injector's runtime dependencies.
    def self.import(name)
      Module.new
    end
  end

  path = File.expand_path('../../src/mod/injector.rb', File.dirname(__FILE__))
  Injector.module_eval(File.read(path), path)

  class ErrorWithoutCause < StandardError
    undef_method :cause if method_defined?(:cause)
  end

  def self.check(code, exception, expected)
    actual = Injector::Err.new(code, exception).to_a
    raise "Expected #{expected.inspect}, got #{actual.inspect}" unless actual == expected
  end

  def self.run
    check('fs.write', IOError.new('write failed'),
      ['fs.write', 'write failed', nil])

    check('bundler.inject.unknown', ErrorWithoutCause.new('injection failed'),
      ['bundler.inject.unknown', 'injection failed', nil])

    check('bundler.inject', Injector::Patch::Injector::InjectionError.new('injection failed'),
      ['bundler.inject', 'injection failed', nil])

    exception = Injector::Patch::Injector::GemfileWriteError.new('append failed', IOError.new('write failed'))
    check('bundler.inject.gemfile.write', exception,
      ['bundler.inject.gemfile.write', 'append failed', '(IOError): write failed'])

    puts 'Injector error reporting: 4 cases passed'
  end
end

InjectorErrorTest.run
