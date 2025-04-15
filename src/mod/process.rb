# ruby-version-min: 1.8.7

LOG = import 'log'

class << self
  def pid
    Process.respond_to?(:pid) ? Process.pid : 0
  end

  def close_fds(opts = {})
    except = opts[:except]

    # TODO: can this overclose? (e.g two IOs to same fileno but one is to be kept open)
    ObjectSpace.each_object(IO) do |io|
      next if except.include?(io)
      next if io.closed?

      begin
        defined?(Fcntl) ? io.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC) : io.close
      rescue ::Exception => err
        LOG.error "error closing FD #{io}: #{err}"
      end
    end
  end
  private :close_fds

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

  def spawn(*args)
    return Process.spawn(*args) if Process.respond_to?(:spawn)

    env = args.first.is_a?(Hash) ? args.shift : {}
    opts = args.last.is_a?(Hash) ? args.pop : {}
    cmd = args

    unsetenv_others = opts.key?(:unsetenv_others) ? opts[:unsetenv_others] : false
    close_others = opts.key?(:close_others) ? opts[:close_others] : true
    chdir = opts[:chdir]
    umask = opts[:umask]

    redirect = opts.reduce({}) do |redir, (k, v)|
      redir[k] = v if [:in, :out, :err, IO, File, Array].any? { |e| e === k }

      redir
    end
    redirect.keys.each { |k| opts.delete(k) }

    cpid = fork do
      File.umask(umask) if umask
      Dir.chdir(chdir)  if chdir

      (ENV.keys - env.keys).each { |k| ENV.delete(k) } if unsetenv_others
      env.each { |k, v| ENV[k] = v }

      # Use Fcntl to atomically close FDs on `exec`
      #
      # In later Ruby versions this is a gem, thus `require`-ing it would
      # result in a gem activation, which may conflict if a different version is
      # bundled by the injectee.
      #
      # Fortunately here:
      #
      # - We're in a fork so no side effect to the injectee
      # - We'll exec right away so all will be forgotten
      #
      # TODO: 'all forgotten'? Maybe env vars might be set?
      require 'fcntl'

      except = []

      redirect.each do |child_fds, parent_fd|
        child_fds = [child_fds] unless child_fds.is_a?(Array)

        parent_io = case parent_fd
                    when Integer
                      IO.for_fd(parent_fd)
                    when IO, File
                      parent_fd
                    when String
                      mode = ([:out, :err] & child_fds).any? ? File::WRONLY : File::RDONLY

                      File.open(parent_fd, mode)
                    when Array
                      case
                      when parent_fd.size == 2 && parent[0] == :child
                        # TODO: not correct, these should be eval'd after redirection to point to _child_ FDs
                        case parent[1]
                        when :in     then $stdin
                        when :out    then $stdout
                        when :err    then $stderr
                        when Integer then IO.for_fd(parent[1])
                        when IO      then parent[1]
                        else raise ArgumentError, "invalid FD: #{child_fd.inspect}"
                        end
                      when parent_fd[0].is_a?(String)
                        path, mode, perm = parent_fd

                        # TODO: does not detect R^W inconsistency
                        mode ||= ([:out, :err] & child_fd).any? ? File::WRONLY : File::RDONLY
                        perm ||= 0644

                        File.open(path, mode, perm)
                      else
                        raise ArgumentError, "invalid redirect: #{parent_fd.inspect}"
                      end
                    when :close
                      false
                    else
                      raise ArgumentError, "invalid redirect: #{parent_fd.inspect}"
                    end

        # TODO: does not handle swaps like [:out => :err, :err => :out]
        child_fds.each do |child_fd|
          child_io = case child_fd
                     when :in     then $stdin
                     when :out    then $stdout
                     when :err    then $stderr
                     when Integer then IO.for_fd(child_fd)
                     when IO      then child_fd
                     else raise ArgumentError, "invalid FD: #{child_fd.inspect}"
                     end

          if parent_io
            child_io.reopen(parent_io)
          else
            child_io.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
          end

          except << child_io
        end
      end

      # TODO: should be [0, 1, 2]
      except = (except + [$stdin, $stdout, $stderr]).uniq

      close_fds(:except => except) if close_others

      exec(*cmd)
    end

    cpid
  end
end
