# ruby-version-min: 1.8.7

PROCESS = import 'process'
RUBY = import 'ruby'
RUNTIME = import 'runtime'

class << self
  def status
    {
      :ruby => {
        :version => RUBY.version,
        :api_version => RUBY.api_version,
        :engine => RUBY.engine,
        :engine_version => RUBY.engine_version,
        :platform => RUBY.platform,
      },
      :process => {
        :exe => PROCESS.exe,
        :name => PROCESS.name,
        :args => PROCESS.args,
        :cmdline => PROCESS.cmdline,
      },
      :fs => {
        :writable => File.writable?(Dir.pwd),
      },
      :runtime => {
        :fork => Process.respond_to?(:fork),
        :spawn => Process.respond_to?(:spawn),
        :platform => RUNTIME.platform,
        :version => RUNTIME.version,
        :name => RUNTIME.name,
      },
    }
  end
end
