INJECTION_DIR = File.expand_path(File.join(__dir__, '..', '..'))

# Idealised syntax
#
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
      { engine: 'ruby', version: '3.5' },
      { engine: 'jruby', version: '9.2' },
      { engine: 'jruby', version: '9.3' },
      { engine: 'jruby', version: '9.4' },
      { engine: 'jruby', version: '10.0' },
    ] => [
      'telemetry should include start',
      'injection should abort',
      'abort reason should include bundler.unlocked',
      'telemetry start should not include result report',
      'telemetry conclusion should include result report',
      'reported result type should be abort',
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
      { engine: 'ruby', version: '3.5' },
      { engine: 'jruby', version: '9.2' },
      { engine: 'jruby', version: '9.3' },
      { engine: 'jruby', version: '9.4' },
      { engine: 'jruby', version: '10.0' },
    ] => [
      'telemetry should include start',
      'injection should abort',
      'abort reason should include bundler.unbundled',
      'telemetry start should not include result report',
      'telemetry conclusion should include result report',
      'reported result type should be abort',
    ],
  },

  { bundle: 'locked' } => [
    [{ fixture: 'deployment' }, { fixture: 'hot', env: 'BUNDLE_DEPLOYMENT=true' }] => {
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'ruby', version: '3.5' },
      ] => [
        'telemetry should include start',
        'injection should proceed',
        'injection should succeed',
        'telemetry should include complete',
        'abort reason should be empty',
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be success',
      ],
    },
    [{ fixture: 'frozen' }, { fixture: 'hot', env: 'BUNDLE_FROZEN=true' }] => {
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'ruby', version: '3.5' },
      ] => [
        'telemetry should include start',
        'injection should proceed',
        'injection should succeed',
        'telemetry should include complete',
        'abort reason should be empty',
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be success',
      ],
    },
    { fixture: 'hot', env: 'BUNDLE_PATH=/bundle' } => {
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
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be abort',
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
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be abort',
      ],
      [
        { engine: 'jruby', version: '9.2' },
        { engine: 'jruby', version: '9.3' },
        { engine: 'jruby', version: '9.4' },
        { engine: 'jruby', version: '10.0' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.engine',
        'abort reason should include runtime.forkless',
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be abort',
      ],
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'ruby', version: '3.5' },
      ] => [
        'telemetry should include start',
        'injection should proceed',
        'injection should succeed',
        'telemetry should include complete',
        'abort reason should be empty',
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be success',
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
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be abort',
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
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be abort',
      ],
      [
        { engine: 'jruby', version: '9.2' },
        { engine: 'jruby', version: '9.3' },
        { engine: 'jruby', version: '9.4' },
        { engine: 'jruby', version: '10.0' },
      ] => [
        'telemetry should include start',
        'injection should abort',
        'abort reason should include runtime.engine',
        'abort reason should include runtime.forkless',
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be abort',
      ],
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'ruby', version: '3.5' },
      ] => [
        'telemetry should include start',
        'injection should proceed',
        'injection should succeed',
        'telemetry should include complete',
        'abort reason should be empty',
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be success',
      ],
    },
    { fixture: 'frozen', inject: true, injector: 'datadog', packaged: true } => {
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'ruby', version: '3.5' },
      ] => [
        'telemetry should include complete',
        'app gemfile should not include datadog',
        'app lockfile should not include datadog',
        'new gemfile should exist',
        'new lockfile should exist',
        'new gemfile should include datadog',
        'new lockfile should include datadog',
        'gem datadog should have require option',
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be success',
      ],
    },
    { fixture: 'hot', inject: true, injector: 'datadog', packaged: true } => {
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'ruby', version: '3.5' },
      ] => [
        'telemetry should include complete',
        'app gemfile should not include datadog',
        'app lockfile should not include datadog',
        'new gemfile should exist',
        'new lockfile should exist',
        'new gemfile should include datadog',
        'new lockfile should include datadog',
        'gem datadog should have require option',
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be success',
      ],
    },
    { fixture: 'deployment', inject: true, injector: 'datadog', packaged: true } => {
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
      ] => [
        'telemetry should include complete',
        'app gemfile should not include datadog',
        'app lockfile should not include datadog',
        'new gemfile should exist',
        'new lockfile should exist',
        'new gemfile should include datadog',
        'new lockfile should include datadog',
        'gem datadog should have require option',
        'telemetry start should not include result report',
        'telemetry conclusion should include result report',
        'reported result type should be success',
      ],
    },
    { inject: true, injector: 'datadog', packaged: true } => {
      [
        { engine: 'ruby', version: '2.6' },
        { engine: 'ruby', version: '2.7' },
        { engine: 'ruby', version: '3.0' },
        { engine: 'ruby', version: '3.1' },
        { engine: 'ruby', version: '3.2' },
        { engine: 'ruby', version: '3.3' },
        { engine: 'ruby', version: '3.4' },
        { engine: 'ruby', version: '3.5' },
      ] => {
        { fixture: 'common' } => [
          'telemetry should include complete',
          'app gemfile should not include datadog',
          'app lockfile should not include datadog',
          'new gemfile should exist',
          'new lockfile should exist',
          'new gemfile should include datadog',
          'new lockfile should include datadog',
          'gem datadog should have require option',
          'gem ffi should have version from app',
          'telemetry start should not include result report',
          'telemetry conclusion should include result report',
          'reported result type should be success',
        ],
        { fixture: 'conflict' } => [
          'telemetry should include error',
          'error reason should include bundler.inject',
          'app gemfile should not include datadog',
          'app lockfile should not include datadog',
        # TODO: disabled due to race condition on naive deletion
        # 'new gemfile should not exist',
        # 'new lockfile should not exist',
          'telemetry start should not include result report',
          'telemetry conclusion should include result report',
          'reported result type should be error',
        ],
        { fixture: 'group' } => [
          'telemetry should include complete',
          'app gemfile should not include datadog',
          'app lockfile should not include datadog',
          'new gemfile should exist',
          'new lockfile should exist',
          'new gemfile should include datadog',
          'new lockfile should include datadog',
          'gem datadog should have require option',
          'gem ffi should have version from app',
          'telemetry start should not include result report',
          'telemetry conclusion should include result report',
          'reported result type should be success',
        ]
      }
    }
  ]
]

def flatten(val, ele=nil, acc=nil)
  ele ||= {}
  acc ||= []

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

example 'telemetry should include start' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.start' } }
end

example 'injection should abort' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' } }
end

example 'abort reason should include runtime.version' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.version') } }
end

example 'abort reason should include runtime.parser' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.parser') } }
end

example 'abort reason should include bundler.deployment' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.deployment') } }
end

example 'abort reason should include bundler.unbundled' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.unbundled') } }
end

example 'abort reason should include bundler.unlocked' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.unlocked') } }
end

example 'abort reason should include bundler.vendored' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:bundler.vendored') } }
end

example 'abort reason should include runtime.engine' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.engine') } }
end

example 'abort reason should include runtime.forkless' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.abort' && p['tags'].include?('reason:runtime.forkless') } }
end

example 'telemetry start should not include result report' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.start' } && !e['metadata'].key?('result') }
end

example 'telemetry conclusion should include result report' do |context|
  context.telemetry.any? { |e| e['points'].none? { |p| p['name'] == 'library_entrypoint.start' } && e['metadata'].key?('result') }
end

example 'reported result type should be success' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| e['metadata']['result'] == 'success' } }
end

example 'reported result type should be skip' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| e['metadata']['result'] == 'skip' } }
end

example 'reported result type should be abort' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| e['metadata']['result'] == 'abort' } }
end

example 'reported result type should be error' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| e['metadata']['result'] == 'error' } }
end

example 'reported result class should be success' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| e['metadata']['result_class'] == 'success' } }
end

example 'reported result class should be success_cached' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| e['metadata']['result_class'] == 'success_cached' } }
end

example 'reported result class should be incompatible_component' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| e['metadata']['result_class'] == 'incompatible_component' } }
end

example 'reported result class should be incompatible_dependency' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| e['metadata']['result_class'] == 'incompatible_dependency' } }
end

example 'reported result class should be internal_error' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| e['metadata']['result_class'] == 'internal_error' } }
end

example 'injection should proceed' do |context|
  # TODO: do it with logs
  true
end

example 'injection should succeed' do |context|
  # TODO: do it with logs
  true
end

example 'telemetry should include complete' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.complete' } }
end

example 'abort reason should be empty' do |context|
  context.telemetry.all? { |e| e['points'].all? { |p| p['name'] != 'library_entrypoint.abort' } }
end

example 'telemetry should include error' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.error' } }
end

example 'error reason should include bundler.inject' do |context|
  context.telemetry.any? { |e| e['points'].any? { |p| p['name'] == 'library_entrypoint.error' && p['tags'].include?('reason:bundler.inject') } }
end

example 'app gemfile should not include datadog' do |context|
  gemfile = File.join(context.path, 'Gemfile')
  !File.read(gemfile).include?('gem "datadog"') rescue nil
end

example 'app lockfile should not include datadog' do |context|
  lockfile = File.join(context.path, 'Gemfile.lock')
  !File.read(lockfile).include?(' datadog ') rescue nil
end

example 'new gemfile should include datadog' do |context|
  gemfile = File.join(context.path, 'datadog.gemfile')
  File.read(gemfile).include?('gem "datadog"') rescue nil
end

example 'new lockfile should include datadog' do |context|
  lockfile = File.join(context.path, 'datadog.gemfile.lock')
  File.read(lockfile).include?(' datadog ') rescue nil
end

example 'gem datadog should have require option' do |context|
  gemfile = File.join(context.path, 'datadog.gemfile')
  File.readlines(gemfile).grep(/gem "datadog"/).any?(%r{(?::require\s*=>\s*|require:\s*)"datadog/single_step_instrument"}) rescue nil
end

example 'gem ffi should have version from app' do |context|
  gemfile = File.join(context.path, 'datadog.gemfile.lock')
  File.readlines(gemfile).grep(/ffi/).any?(%r{1\.17\.0}) rescue nil
end

example 'new gemfile should exist' do |context|
  gemfile = File.join(context.path, 'datadog.gemfile')
  File.exist?(gemfile)
end

example 'new lockfile should exist' do |context|
  lockfile = File.join(context.path, 'datadog.gemfile.lock')
  File.exist?(lockfile)
end

example 'new gemfile should not exist' do |context|
  gemfile = File.join(context.path, 'datadog.gemfile')
  !File.exist?(gemfile)
end

example 'new lockfile should not exist' do |context|
  lockfile = File.join(context.path, 'datadog.gemfile.lock')
  !File.exist?(lockfile)
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
    '3.5' => { tag: '3.5-centos', arch: ['aarch64', 'x86_64'] },
  },
  'jruby' => {
    '9.2' => { tag: '9.2-gnu', arch: ['aarch64', 'x86_64'] },
    '9.3' => { tag: '9.3-gnu', arch: ['aarch64', 'x86_64'] },
    '9.4' => { tag: '9.4-gnu', arch: ['aarch64', 'x86_64'] },
    '10.0' => { tag: '10.0-gnu', arch: ['aarch64', 'x86_64'] },
  }
}

# TODO: these are sane-ish defaults
PLATFORM_ARCH = {
  /^x86_64-linux/  => ['x86_64'],
  /^x86_64-darwin/ => ['x86_64'],
  /^aarch64-linux/ => ['aarch64'],
  /^arm64-darwin/  => ['aarch64', 'x86_64'],
}

def arches_for_platform
  PLATFORM_ARCH.find { |k, _| RUBY_PLATFORM =~ k }&.last
end

def resolve_arch(runtime_arches)
  arches_for_platform.find { |arch| runtime_arches.include?(arch) }
end

def run(*args, engine: nil, version: nil, arch: nil, title: nil)
  env = args.first.is_a?(Hash) ? args.shift : {}

  runtime = RUNTIMES[engine][version] if engine && version

  cmd = []

  env = {
    'DD_TELEMETRY_FORWARDER_PATH' => "#{INJECTION_DIR}/test/bin/forwarder.rb",
    'BUNDLE_APP_CONFIG' => "#{Dir.pwd}/.bundle",
  }.merge(env)

  if runtime
    tag = runtime[:tag]
    arch ||= resolve_arch(runtime[:arch])

    # TODO: what if arch is still nil now

    cmd += %W[
      docker run --rm
    ]

    cmd += %W[
      --interactive --tty
    ] if $stdout.isatty

    cmd += %W[
      --volume #{INJECTION_DIR}:#{INJECTION_DIR}:rw
      --volume datadog-injector-rb-bundle-shared-#{engine}-#{tag}-#{arch}:/usr/local/bundle:rw
      --volume datadog-injector-rb-bundle-deployment-#{engine}-#{tag}-#{arch}:#{Dir.pwd}/vendor/bundle:rw
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

  out_r, out_w = IO.pipe
  err_r, err_w = IO.pipe

  out_thr = Thread.new do
    mark = true

    loop do
      io = out_r

      if io.eof?
        break
      end

      data = io.read(1)

      if mark
        $stderr.write("┃ ")
        mark = false
      end

      $stderr.write(data)

      mark = true if data == "\n"
    end
  end

  err_thr = Thread.new do
    mark = true

    loop do
      io = err_r

      if io.eof?
        break
      end

      data = io.read(1)

      if mark
        $stderr.write("┇ ")
        mark = false
      end

      $stderr.write(data)

      mark = true if data == "\n"
    end
  end

  $stdout.write("┏━ #{title || cmd.first}\n")

  if false
    $stdout.write("┋ #{cmd.inspect}\n")
    $stdout.write("┣━ \n")
  end

  pid = spawn(env, *cmd, :out => out_w, :err => err_w)

  _pid, status = Process.waitpid2(pid).tap do
    out_w.close
    err_w.close
  end
ensure
  $stdout.write("┗━ ")
  if status
    $stdout.write("#{status}\n")
  else
    $stdout.write("#{status}\n")
  end

  out_thr.join
  err_thr.join
end

class Context
  attr_reader :telemetry, :path

  def initialize(telemetry: telemetry, path: path)
    @telemetry = telemetry
    @path = path
  end
end

def main(argv)
  keep = false
  filter = []

  loop do
    arg = argv.shift

    case arg
    when '-k', '--keep'
      keep = true
    when '-f', '--filter'
      f = argv.shift
      raise ArgumentError if f.nil?
      filter << f
    when nil
      break
    else
      next
    end
  end

  err = []
  miss = []
  fail = []

  matrix = flatten(SUITE)

  # TODO: matrix should be NOOP-explorable from the command line

  rows = matrix.uniq

  filter.each do |f|
    rows = rows.select { |e| f.split(',').map { |f| k, v = f.split(':'); e[k.to_sym] == (%w[true false nil].include?(v) ? eval(v) : v) }.reduce(:&) }
  end

  groups = rows.group_by { |e| e.slice(*(e.keys - [:test])) }

  require 'fileutils'
  require 'securerandom'
  require 'json'

  start = Time.now

  groups.each do |group, rows|
    uuid = SecureRandom.uuid

    puts "╭─────┈┄╌"
    puts "│ run: #{group.inspect} uuid: #{uuid}"
    puts "╰─────┈┄╌"

    tmp = "#{INJECTION_DIR}/test/tmp/run/#{group[:fixture]}-#{uuid}"
    FileUtils.mkdir_p(tmp)
    begin
      fixture = group[:fixture]
      FileUtils.cp_r "test/fixtures/#{fixture}", tmp

      lock = group[:bundle] == 'locked'
      packaged = group[:packaged]

      if packaged
        package_basepath = "#{INJECTION_DIR}/test/packages/#{group[:injector]}"
        package_gem_home = "#{package_basepath}/#{group[:version]}.0"

        env = { 'BUNDLE_GEMFILE' => "#{package_gem_home}/Gemfile", 'GEM_HOME' => package_gem_home }
        pid, status = run env, *%W[ bundle install ], engine: group[:engine], version: group[:version], title: 'package injection gems'
        if status.exitstatus != 0
          puts "╭─────┈┄╌"
          puts "│ ERR: #{group.inspect} uuid: #{uuid}"
          puts "╰─────┈┄╌"

          err << group
          next
        end
      end

      Dir.chdir tmp do
        Dir.chdir fixture do
          if lock
            # ignore fixture config, notably development/frozen which would prevent lock
            env = { 'BUNDLE_APP_CONFIG' => '/nowhere' }
            pid, status = run env, *%W[ bundle lock ], engine: group[:engine], version: group[:version], title: 'lock fixture'
            if status.exitstatus != 0
              puts "╭─────┈┄╌"
              puts "│ ERR: #{group.inspect} uuid: #{uuid}"
              puts "╰─────┈┄╌"

              err << group
              next
            end

            env = if (e = group[:env])
                    k, v = e.split('=', 2)
                    { k => v }
                  else
                    {}
                  end
            pid, status = run env, *%W[ bundle install ], engine: group[:engine], version: group[:version], title: 'install fixture'
            if status.exitstatus != 0
              puts "╭─────┈┄╌"
              puts "│ ERR: #{group.inspect} uuid: #{uuid}"
              puts "╰─────┈┄╌"

              err << group
              next
            end
          end

          env = if (e = group[:env])
                  k, v = e.split('=', 2)
                  { k => v }
                else
                  {}
                end
          env = { 'DD_TELEMETRY_FORWARDER_LOG' => "#{tmp}/forwarder.log" }.merge(env)
          env['DD_INTERNAL_RUBY_INJECTOR'] = 'false' unless group[:inject]
          env['DD_INTERNAL_RUBY_INJECTOR_BASEPATH'] = "#{INJECTION_DIR}/test/packages/#{group[:injector]}"
          env['RUBYOPT'] = "-r#{INJECTION_DIR}/src/injector.rb"

          pid, status = if lock
                          run env, *%W[ bundle exec ruby stub.rb ],
                              engine: group[:engine], version: group[:version],
                              title: 'run fixture stub'
                        else
                          run env, *%W[ ruby stub.rb ],
                              engine: group[:engine], version: group[:version],
                              title: 'run fixture stub'
                        end

          if status.exitstatus != 0
            puts "╭─────┈┄╌"
            puts "│ ERR: #{group.inspect} uuid: #{uuid}"
            puts "╰─────┈┄╌"

            err << group
            next
          end

          if File.exist? "#{tmp}/forwarder.log"
            telemetry = File.open("#{tmp}/forwarder.log") { |f| f.each_line.map { |l| JSON.parse(l) } }

            puts "╭─────┈┄╌"
            rows.each do |row|
              puts "│ test: #{row[:test].inspect}"

              test = EXAMPLES[row[:test]]

              context = Context.new(
                telemetry: telemetry,
                path: Dir.pwd,

                # TODO: add stdout+stderr
              )

              if test.nil?
                puts "| ╰── MISS"
                miss << row[:test]
                next
              end

              res = begin
                test.call(context)
              rescue StandardError => e
                puts "| ╰── ERR: #{e.class.name}(#{e.message.inspect})"
                err << row
                next
              end

              if res
                puts "| ╰── OK"
              else
                puts "| ╰── FAIL"
                fail << row
              end
            end
            puts "╰─────┈┄╌"

          else
            puts "╭─────┈┄╌"
            puts "│ ERR: #{group.inspect} uuid: #{uuid} forwarder: 'no log'"
            puts "╰─────┈┄╌"

            err << group
            next
          end
        end
      end
    ensure
      FileUtils.rm_rf tmp unless keep
    end
  end

  delta = Time.now - start

  if fail.count > 0
    puts "\n!!! failed: #{fail.count}"
    fail.uniq.each do |f|
      puts "!!! -- #{f.inspect}"
    end
  end

  if err.count > 0
    puts "\n!!! errors: #{err.count}"
    err.uniq.each do |e|
      puts "!!! -- #{e.inspect}"
    end
  end

  if miss.count > 0
    puts "\n!!! missing: #{miss.uniq.count}"
    miss.uniq.each { |m| puts "!!! -- #{m}" }
  end

  puts "\n=== ran:#{rows.count} fail:#{fail.count} miss:#{miss.uniq.count} err:#{err.count} time:#{delta}"

  exit 1 if fail.count + miss.count + err.count > 0
end

main(ARGV.dup) if $0 == __FILE__
