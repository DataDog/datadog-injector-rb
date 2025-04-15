#!/usr/bin/env ruby

require 'fileutils'
require 'open3'

TEST_DIR = File.expand_path(File.dirname(__FILE__))
FIXTURES_DIR = File.join(TEST_DIR, 'fixtures')
TMP_DIR = File.join(TEST_DIR, 'tmp')
#RUBY_API_VERSION = RUBY_VERSION.gsub(/^(\d+\.\d+)\..*/, '\1.0')
RUBY_API_VERSION = RbConfig::CONFIG["ruby_version"]
RUBY = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name']).sub(/.*\s.*/m, '"\&"')
BUNDLER = ENV['PATH'].split(':').find { |p| f = File.join(p, 'bundle'); File.executable?(f) && break f }
INJECTOR = File.expand_path('injector.rb')

p RUBY
p BUNDLER
p INJECTOR

test = 'hot'

TEST_FIXTURE = File.join(FIXTURES_DIR, test)
GEM_HOME = File.join(TMP_DIR, test, 'gems', 'ruby', RUBY_API_VERSION)
p GEM_HOME

FileUtils.mkdir_p GEM_HOME


env = {
  'GEM_HOME' => GEM_HOME,
}
exe = [
  BUNDLER,
  'bundle',
]
args = [
  'install',
]
opts = {
  chdir: TEST_FIXTURE,
  unsetenv_others: true,
}
stdout, stderr, status = Open3.capture3(env, exe, *args, opts)
p status
puts stdout
puts stderr


env = {
  'GEM_HOME' => GEM_HOME,
}
exe = [
  BUNDLER,
  'bundle',
]
args = [
  'info',
  'rack',
]
opts = {
  chdir: TEST_FIXTURE,
  unsetenv_others: true,
}
stdout, stderr, status = Open3.capture3(env, exe, *args, opts)
p status
puts stdout
puts stderr


env = {
  'GEM_HOME' => GEM_HOME,
}
exe = [
  '/usr/bin/env',
  'env',
]
args = [
]
opts = {
  chdir: TEST_FIXTURE,
  unsetenv_others: true,
}
stdout, stderr, status = Open3.capture3(env, exe, *args, opts)
p status
puts stdout
puts stderr


env = {
  'GEM_HOME' => GEM_HOME,
}
exe = [
  '/bin/pwd',
  'pwd',
]
args = [
]
opts = {
  chdir: TEST_FIXTURE,
  unsetenv_others: true,
}
stdout, stderr, status = Open3.capture3(env, exe, *args, opts)
p status
puts stdout
puts stderr


env = {
  'GEM_HOME' => GEM_HOME,
}
exe = [
  RUBY,
  'ruby',
]
args = [
  '-e',
  'p Dir.pwd',
]
opts = {
  chdir: TEST_FIXTURE,
  unsetenv_others: true,
}
stdout, stderr, status = Open3.capture3(env, exe, *args, opts)
p status
puts stdout
puts stderr


env = {
  'GEM_HOME' => GEM_HOME,
}
exe = [
  RUBY,
  'ruby',
]
args = [
  '-e',
  'p ENV',
]
opts = {
  chdir: TEST_FIXTURE,
  unsetenv_others: true,
}
stdout, stderr, status = Open3.capture3(env, exe, *args, opts)
p status
puts stdout
puts stderr


env = {
  'GEM_HOME' => GEM_HOME,
# 'BUNDLE_FROZEN' => 'true',
  'BUNDLE_DEPLOYMENT' => 'true',
# 'BUNDLE_PATH' => '/foo',
  'RUBYOPT' => "-r #{INJECTOR}",
}
exe = [
  RUBY,
  'ruby',
]
args = [
  '-e',
  'p ENV',
]
opts = {
  chdir: TEST_FIXTURE,
  unsetenv_others: true,
}
stdout, stderr, status = Open3.capture3(env, exe, *args, opts)
p status
puts stdout
puts stderr

env = {
  'GEM_HOME' => GEM_HOME,
# 'BUNDLE_FROZEN' => 'true',
  'BUNDLE_DEPLOYMENT' => 'true',
  'BUNDLE_PATH' => File.dirname(File.dirname(GEM_HOME)),
  'RUBYOPT' => "-r#{INJECTOR}",
}
exe = [
  BUNDLER,
  'bundle',
]
args = [
  'exec',
  RUBY,
  '-e',
  'p ENV',
]
opts = {
  chdir: TEST_FIXTURE,
  unsetenv_others: true,
}
stdout, stderr, status = Open3.capture3(env, exe, *args, opts)
p status
puts stdout
puts stderr


env = {
  'GEM_HOME' => GEM_HOME,
  'BUNDLE_FROZEN' => 'true',
# 'BUNDLE_DEPLOYMENT' => 'true',
# 'BUNDLE_PATH' => '/foo',
  'RUBYOPT' => "-r#{INJECTOR}",
}
exe = [
  BUNDLER,
  'bundle',
]
args = [
  'exec',
  RUBY,
  '-e',
  'p ENV',
]
opts = {
  chdir: TEST_FIXTURE,
  unsetenv_others: true,
}
stdout, stderr, status = Open3.capture3(env, exe, *args, opts)
p status
puts stdout
puts stderr
