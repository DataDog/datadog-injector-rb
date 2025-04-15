# ruby-version-min: 1.8.7

class AssertError < StandardError; end

class Test
  def assert(message = nil, condition = nil, &block)
    condition = lambda { |v| v == true } if condition.nil?

    if block.respond_to?(:source_location)
      file, line = block.source_location
      puts "    #{File.read(file).split("\n")[line - 1].gsub(/^\s+/, '')}"
    end

    actual = block.call
    result = condition.call(actual)

    unless result == true
      error = AssertError.new message.gsub('%{actual}', actual.inspect)
      error.set_backtrace caller.reject { |v| v =~ /in 'Test#/ }
      raise error
    end
  end

  def assert_equal(expected, &actual)
    assert("expected: #{expected.inspect} actual: %{actual}", lambda { |v| expected == v }, &actual)
  end
end

def self.autorun!
  at_exit do
    classes = ::Object.constants.grep(/^Test[A-Z]/).map do |const|
      ::Object.const_get(const)
    end

    tests = classes.reduce([]) do |acc, klass|
      acc << [klass, klass.instance_methods.grep(/^test_/)]
    end

    tests.each do |klass, methods|
      puts klass.name

      methods.each do |method|
        puts "  #{method.to_s}"

        klass.new.send(method)
      end
    end
  end
end
