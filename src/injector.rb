# ruby-version-min: 1.8.7

# This file's intent is to be parseable and executable by "all" ruby versions

# Create a lexical scope, guaranteeing no variable escape (in `main` or otherwise)
#
# This Module instance is not referenced and will entirely disappear on GC (as
# well as anything it has created)
#
# Notes:
# - no naked constant shall be defined here, or they will leak out.
# - while variables will not leak they may be closed over (and thus
#   overwritten) should they exist beforehand: so avoid variables too.
Module.new do
  # Bootstrap module loader
  #
  # `require` is not used:
  #
  # - to not trigger any potential internal caching code
  # - to not rely on side-effectful global definitions such as constants
  #
  # Instead:
  #
  # - each file imported will be evaluated within a dynamic module
  # - the module is returned, ready to be assigned to a local variable

  class << self
    # Define root from which to look for imports
    def root
      @root ||= File.join(File.expand_path(File.dirname(__FILE__)), 'mod')
    end

    # Track loaded modules, for "import-once" `require`-like behaviour
    def imported_modules
      @imported_modules ||= {}
    end

    # Import facility
    def import(name)
      path = File.join(root, "#{name}.rb")

      if !File.readable?(path)
        raise LoadError, "no such file to import -- #{path}"
      end

      if (mod = imported_modules[path])
        return mod
      end

      # Create module, with:
      #
      # - a helpful name
      # - useful debuggable information
      # - importing facility as a method
      mod = Module.new do
        def self.name
          @name
        end

        def self.to_s
          "#<Module:%#016x %s>" % [object_id, name]
        end

        def self.inspect
          "#<Module:%#016x %s>" % [object_id, name]
        end

        def self.import(name)
          @import_proc.call(name)
        end
      end

      # Inject values
      mod.instance_variable_set(:@name, name)
      mod.instance_variable_set(:@import_proc, method(:import))

      # Expose module immediately, which gracefully handles circular
      # references at the cost of the module being lazily filled in
      # later (just like circular requires).
      imported_modules[path] = mod

      # Read and eval source in module context
      source = File.read(path)
      mod.module_eval(source, path)  # This makes all constant definitions scoped to the module

      # Return module for assignment
      mod
    end
  end

  # From this unreferenced Module instance, import main module, which executes right away
end.import 'main'
