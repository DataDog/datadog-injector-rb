# ruby-version-min: 1.8.7

PROCESS = import 'process'

DEBUG   = 0
INFO    = 1
WARN    = 2
ERROR   = 3
FATAL   = 4
UNKNOWN = 5

Format = "%.1s, [%s #%d] %5s -- %s: %s\n"
DatetimeFormat = '%Y-%m-%dT%H:%M:%S.%6N%z'

class << self
  def << msg
    logdev && logdev.write(msg)
  end

  def logdev
    $stderr
  end

  def progname
    'entrypoint'
  end

  def level
    @level ||= case ENV['DD_INTERNAL_RUBY_INJECTOR_LOG_LEVEL']
               when 'DEBUG', 0 then DEBUG
               when 'INFO',  1 then INFO
               when 'WARN',  2 then WARN
               when 'ERROR', 3 then ERROR
               when 'FATAL', 4 then FATAL
               else UNKNOWN
               end
  end

  def add(severity, message = nil, progname = nil)
    severity ||= UNKNOWN

    return true if logdev.nil? || severity < level

    progname ||= self.progname

    message ||= block_given? ? yield : progname.tap { progname = self.progname }

    self << format_message(severity, Time.now, progname, message)

    true
  end
  alias :log :add

  def debug(progname = nil, &block)
    add(DEBUG, nil, progname, &block)
  end

  def info(progname = nil, &block)
    add(INFO, nil, progname, &block)
  end

  def warn(progname = nil, &block)
    add(WARN, nil, progname, &block)
  end

  def error(progname = nil, &block)
    add(ERROR, nil, progname, &block)
  end

  def fatal(progname = nil, &block)
    add(FATAL, nil, progname, &block)
  end

  def unknown(progname = nil, &block)
    add(UNKNOWN, nil, progname, &block)
  end

  private

  def format_message(severity, time, progname, message)
    sevstr = case severity
             when DEBUG   then 'DEBUG'
             when INFO    then 'INFO'
             when WARN    then 'WARN'
             when ERROR   then 'ERROR'
             when FATAL   then 'FATAL'
             else              'UNKNOWN'
             end

    sprintf(Format, sevstr, format_datetime(time), PROCESS.pid, sevstr, progname, msg2str(message))
  end

  def format_datetime(time)
    strftime(time, DatetimeFormat)
  end

  if Time.now.strftime('%N') == '%N'
    def strftime(time, format)
      # TODO: handle %%
      format = format.gsub(/%L/, '%3N')
      format = format.gsub(/%(\d*)N/) do |m|
        width = $1 == '' ? 9 : $1.to_i
        frac = time.respond_to?(:nsec) ? time.nsec : time.usec

        frac.to_s[0, width].ljust(width, '0')
      end

      time.strftime(format)
    end
  else
    def strftime(time, format)
      time.strftime(format)
    end
  end

  def msg2str(msg)
    case msg
    when ::String
      msg
    when ::Exception
      "#{ msg.message } (#{ msg.class })\n#{ msg.backtrace.join("\n") if msg.backtrace }"
    else
      msg.inspect
    end
  end
end
