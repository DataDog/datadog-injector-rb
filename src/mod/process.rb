# ruby-version-min: 1.8.7

class << self
  def pid
    Process.respond_to?(:pid) ? Process.pid : 0
  end

  def exe
    File.readlink('/proc/self/exe') if File.exist?('/proc/self/exe')
  end

  def cmdline
    File.read('/proc/self/cmdline').split("\0").reject { |arg| arg.empty? } if File.exist?('/proc/self/cmdline')
  end

  def name
    $0
  end

  def args
    ARGV
  end

  # Evaluate block in child process and return result
  #
  # If an exception is raised, it is returned as-is.
  #
  # Note: deserialization of constants unknown to the parent (including
  # instances of unknown classes or raised exceptions) will lead to a NameError.
  def child_eval(&block)
    rd, wr = IO.pipe

    pid = fork do
      begin
        rd.close
        begin
          result = block.call
        rescue Exception => e
          result = e
        end
        wr.write(Marshal.dump(result))
      ensure
        wr.close
      end
      exit!(0)
    end

    wr.close
    result = Marshal.load(rd.read)
    Process.waitpid(pid)
    rd.close

    raise result if result.is_a?(Exception)
    result
  end
end
