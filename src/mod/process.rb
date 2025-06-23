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
end
