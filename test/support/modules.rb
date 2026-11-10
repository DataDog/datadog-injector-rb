# ruby-version-min: 1.8.7

module TestModules
  def self.import(name)
    @modules ||= {}
    return @modules[name] if @modules.key?(name)

    mod = Module.new do
      def self.import(name)
        TestModules.import(name)
      end
    end
    @modules[name] = mod
    path = File.expand_path("../../src/mod/#{name}.rb", File.dirname(__FILE__))
    mod.module_eval(File.read(path), path)
    mod
  end

  def self.assert_equal(expected, actual)
    raise "Expected #{expected.inspect}, got #{actual.inspect}" unless expected == actual
  end
end
