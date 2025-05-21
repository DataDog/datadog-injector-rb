# ruby-version-min: 1.8.7

RUBY = import 'ruby'

class << self
  def name
    if RUBY.platform == 'java'
      java.lang.System.get_property('java.vm.name')
    else
      RUBY.engine
    end
  end

  def version
    if RUBY.platform == 'java'
      java.lang.System.get_property('java.version')
    else
      RUBY.version
    end
  end

  def platform
    if RUBY.platform == 'java'
      os_name = java.lang.System.get_property('os.name')
      os_arch = java.lang.System.get_property('os.arch')
      os = case os_name
           when /linux/i then 'linux'
           when /mac/i   then 'darwin'
           else raise RuntimeError, "unsupported JRuby os.name: #{os_name.inspect}"
           end
      cpu = case os_arch
            when 'amd64' then 'x86_64'
            when 'aarch64' then os == 'darwin' ? 'arm64' : 'aarch64'
            else raise RuntimeError, "unsupported JRuby os.arch: #{os_arch.inspect}"
            end

      "#{cpu}-#{os}"
    else
      RUBY.platform
    end
  end
end
