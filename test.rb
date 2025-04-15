
INJECTION_DIR="/Users/loic.nageleisen/Source/github.com/DataDog/datadog-injector-rb"
THIS = __dir__

# fixture:unbundled
#   for ruby:1.8..3.4 jruby:9.2..9.4
#     telemetry should include start
#     injection should abort
#     abort reason should include bundler.unbundled
#
# for fixture:deployment fixture:hot,env:BUNDLER_DEPLOYMENT=true
#   for ruby:1.8..3.4 jruby:9.2..9.4
#     telemetry should include start
#     injection should abort
#     abort reason should include bundler.deployment
#
# for fixture:frozen fixture:hot,env:BUNDLER_FROZEN=true
#   for ruby:1.8..3.4 jruby:9.2..9.4
#     telemetry should include start
#     injection should abort
#     abort reason should include bundler.frozen
#
# fixture:[hot,deployment,frozen],bundle:unlocked
#   for ruby:1.8..3.4 jruby:9.2..9.4
#     telemetry should include start
#     injection should abort
#     abort reason should include bundler.unlocked
#
# for fixture:hot fixture:unbundled,env:BUNDLE_GEMFILE=../hot/Gemfile
#   for ruby:1.8..2.3
#     telemetry should include start
#     telemetry should include runtime.parser
#
#   for ruby:1.8..2.5
#     telemetry should include start
#     telemetry should include runtime.version
#
#   for jruby:9.2..9.4
#     telemetry should include start
#     telemetry should include runtime.engine
#     telemetry should include runtime.forkless
#
#   for ruby:2.6..3.4
#     injection should start
#       telemetry should include start
#     injection should proceed
#       telemetry should include start
#     injection should succeed
#       telemetry should include complete

SUITE = [
# [{ fixture: ['hot', 'deployment', 'frozen'], bundle: 'unlocked' }] => {
  [
    { fixture: 'hot', bundle: 'unlocked' },
    { fixture: 'deployment', bundle: 'unlocked' },
    { fixture: 'frozen', bundle: 'unlocked' },
    { fixture: 'unbundled' },
  ] => {
    [
      { engine: 'ruby', version: '1.8' },
      { engine: 'ruby', version: '1.9' },
      { engine: 'ruby', version: '2.0' },
      { engine: 'ruby', version: '2.1' },
      { engine: 'ruby', version: '2.2' },
      { engine: 'ruby', version: '2.3' },
      { engine: 'ruby', version: '2.4' },
      { engine: 'ruby', version: '2.5' },
      { engine: 'ruby', version: '2.6' },
      { engine: 'ruby', version: '2.7' },
      { engine: 'ruby', version: '3.0' },
      { engine: 'ruby', version: '3.1' },
      { engine: 'ruby', version: '3.2' },
      { engine: 'ruby', version: '3.3' },
      { engine: 'ruby', version: '3.4' },
      { engine: 'jruby', version: '9.2' },
      { engine: 'jruby', version: '9.3' },
      { engine: 'jruby', version: '9.4' },
    ] => [
      'telemetry should include start',
      'injection should abort',
      'abort reason should include bundler.unlocked',
    ],
  },

  { fixture: 'unbundled' } => {
    [
      { engine: 'ruby', version: '1.8' },
      { engine: 'ruby', version: '1.9' },
      { engine: 'ruby', version: '2.0' },
      { engine: 'ruby', version: '2.1' },
      { engine: 'ruby', version: '2.2' },
      { engine: 'ruby', version: '2.3' },
      { engine: 'ruby', version: '2.4' },
      { engine: 'ruby', version: '2.5' },
      { engine: 'ruby', version: '2.6' },
      { engine: 'ruby', version: '2.7' },
      { engine: 'ruby', version: '3.0' },
      { engine: 'ruby', version: '3.1' },
      { engine: 'ruby', version: '3.2' },
      { engine: 'ruby', version: '3.3' },
      { engine: 'ruby', version: '3.4' },
      { engine: 'jruby', version: '9.2' },
      { engine: 'jruby', version: '9.3' },
      { engine: 'jruby', version: '9.4' },
    ] => [
      'telemetry should include start',
      'injection should abort',
      'abort reason should include bundler.unbundled',
    ],
  },

  { bundle: 'locked' } => [
    [{ fixture: 'deployment' }, { fixture: 'hot', env: 'BUNDLE_DEPLOYMENT=true' }] => {
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
        { engine: 'ruby', version: '2.4' },
        { engine: 'ruby', version: '2.5' },
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'jruby', version: '9.2' },
        { engine: 'jruby', version: '9.3' },
        { engine: 'jruby', version: '9.4' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include bundler.deployment',
      ],
    },
    [{ fixture: 'frozen' }, { fixture: 'hot', env: 'BUNDLE_FROZEN=true' }] => {
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
        { engine: 'ruby', version: '2.4' },
        { engine: 'ruby', version: '2.5' },
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'jruby', version: '9.2' },
        { engine: 'jruby', version: '9.3' },
        { engine: 'jruby', version: '9.4' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include bundler.frozen',
      ],
    },
    { fixture: 'hot' } => {
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.parser',
      ],
      [
        { engine: 'ruby', version: '1.8' },
        { engine: 'ruby', version: '1.9' },
        { engine: 'ruby', version: '2.0' },
        { engine: 'ruby', version: '2.1' },
        { engine: 'ruby', version: '2.2' },
        { engine: 'ruby', version: '2.3' },
        { engine: 'ruby', version: '2.4' },
        { engine: 'ruby', version: '2.5' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.version',
      ],
      [
        { engine: 'jruby', version: '9.2' },
        { engine: 'jruby', version: '9.3' },
        { engine: 'jruby', version: '9.4' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.engine',
        'abort reason should include runtime.forkless',
      ],
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
      ] => [
        'telemetry should include start',
        'injection should proceed',
        'injection should succeed',
        'telemetry should include complete',
        'abort reason should be empty',
      ],
    },
  ]
]

# matrix = []
#
# SUITE.each do |per_fixture|
#   per_fixture.each do |fixture, per_runtime|
#     per_runtime.each do |runtimes, tests|
#       runtimes.each do |runtime|
#         tests.each do |test|
#           matrix << { fixture: fixture[:fixture], engine: runtime[:engine], version: runtime[:version], test: test }
#         end
#       end
#     end
#   end
# end

def flatten(val, ele={}, acc=[])
  case val
  when String, Symbol
    acc << ele.merge(:test => val)
  when Array
    val.each { |v| flatten(v, ele, acc) }
  when Hash
    val.each do |k, v|
      case k
      when Symbol, String
        flatten(v, ele.merge(k => true), acc)
      when Array
        k.each { |kv| flatten(v, ele.merge(kv), acc) }
      when Hash
        flatten(v, ele.merge(k), acc)
      end
    end
  end

  acc
end

EXAMPLES = {}

def example(desc, &block)
  EXAMPLES[desc] = block
end

example 'telemetry should include start' do |telemetry|
  telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.start' } }
end

example 'injection should abort' do |telemetry|
  telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' } }
end

example 'abort reason should include runtime.version' do |telemetry|
  telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.version') } }
end

example 'abort reason should include runtime.parser' do |telemetry|
  telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.parser') } }
end

example 'abort reason should include bundler.deployment' do |telemetry|
  telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.deployment') } }
end

example 'abort reason should include bundler.frozen' do |telemetry|
  telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.frozen') } }
end

example 'abort reason should include bundler.unbundled' do |telemetry|
  telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.unbundled') } }
end

example 'abort reason should include bundler.unlocked' do |telemetry|
  telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.unlocked') } }
end


RUNTIMES = {
  'ruby' => {
    '1.8' => { tag: '1.8-centos', arch: ['x86_64'] },
    '1.9' => { tag: '1.9-centos', arch: ['x86_64'] },
    '2.0' => { tag: '2.0-centos', arch: ['x86_64'] },
    '2.1' => { tag: '2.1-centos', arch: ['x86_64'] },
    '2.2' => { tag: '2.2-centos', arch: ['aarch64', 'x86_64'] },
    '2.3' => { tag: '2.3-centos', arch: ['aarch64', 'x86_64'] },
    '2.4' => { tag: '2.4-centos', arch: ['aarch64', 'x86_64'] },
    '2.5' => { tag: '2.5-centos', arch: ['aarch64', 'x86_64'] },
    '2.6' => { tag: '2.6-centos', arch: ['aarch64', 'x86_64'] },
    '2.7' => { tag: '2.7-centos', arch: ['aarch64', 'x86_64'] },
    '3.0' => { tag: '3.0-centos', arch: ['aarch64', 'x86_64'] },
    '3.1' => { tag: '3.1-centos', arch: ['aarch64', 'x86_64'] },
    '3.2' => { tag: '3.2-centos', arch: ['aarch64', 'x86_64'] },
    '3.3' => { tag: '3.3-centos', arch: ['aarch64', 'x86_64'] },
    '3.4' => { tag: '3.4-centos', arch: ['aarch64', 'x86_64'] },
  },
  'jruby' => {
    '9.2' => { tag: '9.2-gnu', arch: ['aarch64', 'x86_64'] },
    '9.3' => { tag: '9.2-gnu', arch: ['aarch64', 'x86_64'] },
    '9.4' => { tag: '9.2-gnu', arch: ['aarch64', 'x86_64'] },
  }
}

def run(*args, engine: nil, version: nil, arch: nil)
  env = args.first.is_a?(Hash) ? args.shift : {}

  runtime = RUNTIMES[engine][version] if engine && version

  cmd = []

  env = {
    'DD_TELEMETRY_FORWARDER_PATH' => "#{INJECTION_DIR}/forwarder.rb"
  }.merge(env)

  if runtime
    tag = runtime[:tag]
    arch = runtime[:arch].first

    cmd += %W[
      docker run --rm --interactive --tty
      --volume #{INJECTION_DIR}:#{INJECTION_DIR}:rw
      --volume datadog-injector-rb-#{engine}-#{tag}-#{arch}:/usr/local/bundle:rw
      --volume #{Dir.pwd}:#{Dir.pwd}:rw
      --workdir #{Dir.pwd}
      --platform linux/#{arch}
    ]

    cmd += env.keys.map { |e| %W[ --env #{e} ] }.flatten

    cmd += %W[
      ghcr.io/datadog/images-rb/engines/#{engine}:#{tag}
    ]
  end

  cmd += args

  #spawn(env, *cmd, [:out, :err] => '/dev/null')
  #spawn(env, *cmd, [:err] => '/dev/null')
  spawn(env, *cmd)
end

def main(argv)
  start = Time.now
  matrix = flatten(SUITE)
  keep = false

  #pp matrix
  #p matrix.count
  #p matrix.uniq.count
  #pp matrix.group_by { |e| [e[:engine], e[:version]] }

  rows = matrix.select { |e| e[:engine] == 'ruby' && e[:version] == '1.8' && ['deployment', 'frozen'].include?(e[:fixture]) }

  require 'fileutils'
  require 'securerandom'
  require 'json'

  rows.each do |row|
    puts "=== run: #{row.inspect}"

    tmp = "#{INJECTION_DIR}/test/tmp/run/hot-#{SecureRandom.uuid}"
    FileUtils.mkdir_p(tmp)
    begin
      fixture = row[:fixture]
      FileUtils.cp_r "test/fixtures/#{fixture}", tmp

      lock = row[:bundle] == 'locked'

      Dir.chdir tmp do
        Dir.chdir fixture do
          if lock
            pid = run *%W[ bundle install ], engine: row[:engine], version: row[:version]
            _pid, status = Process.waitpid2(pid)
            if status.exitstatus != 0
              puts "==> ERR"
              next
            end
          end

          env = if (e = row[:env])
                  k, v = e.split('=', 2)
                  { k => v }
                else
                  {}
                end

          pid = run({ 'DD_TELEMETRY_FORWARDER_LOG' => "#{tmp}/forwarder.log" }.merge(env),
                    *%W[ ruby -r #{INJECTION_DIR}/src/injector.rb stub.rb ],
                    engine: row[:engine], version: row[:version])
          _pid, status = Process.waitpid2(pid)
          if status.exitstatus != 0
            puts "==> ERR"
            next
          end

          if File.exist? "#{tmp}/forwarder.log"
            test = EXAMPLES[row[:test]]
            telemetry = File.open("#{tmp}/forwarder.log") { |f| f.each_line.map { |l| JSON.parse(l) } }

            if test.nil?
              puts "==> MISS"
            elsif test.call(telemetry)
              puts "==> OK"
            else
              puts "==> FAIL"
            end

          # FileUtils.mv "#{tmp}/forwarder.log", "#{INJECTION_DIR}/forwarder.log"
          end
        end
      end
    ensure
      FileUtils.rm_rf tmp unless keep
    end
  end

  delta = Time.now - start
  puts "=== ran:#{rows.count} time:#{delta}"
end



#matrix.uniq.each do |row|
#  puts '*' * 80
#  pid = run engine: row[:engine], version: row[:version]
#  puts '*' * 80
#  p Process.waitpid2(pid)
#  puts '*' * 80
#  puts
#end

#matrix.uniq.select { |row| row[:engine] == 'ruby' && row[:version] == (RUBY_VERSION =~ /^(\d+\.\d+)/ && $1) }.each do |row|
#   puts '*' * 80
#   pid = run
#   puts '*' * 80
#   p Process.waitpid2(pid)
#   puts '*' * 80
#   puts
#end

# pid = run
# Process.waitpid2 pid

# pid = run engine: 'ruby', version: '1.8'
# Process.waitpid2 pid

# pid = run engine: 'ruby', version: '3.4', arch: 'aarch64'
# Process.waitpid2 pid

# pid = run engine: 'jruby', version: '9.4', arch: 'aarch64'
# Process.waitpid2 pid

main(ARGV) if $0 == __FILE__
