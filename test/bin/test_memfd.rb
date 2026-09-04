#!/usr/bin/env ruby

def load_memfd
  Module.new.tap do |mod|
    path = File.expand_path('../../src/mod/memfd.rb', __dir__)
    mod.module_eval(File.read(path), path)
  end
end

def assert(message)
  raise message unless yield
end

producer = load_memfd
consumer = load_memfd
content = "gem \"example\"\n" * 100_000
payload = {
  :gemfile_path => '/app/Gemfile',
  :lockfile_path => '/app/Gemfile.lock',
  :gemfile_content => content,
  :lockfile_content => "GEM\n",
  :original_gemfile_content => "gem \"rack\"\n",
  :original_lockfile_content => "GEM\n",
}

fd = producer.create(payload)
raise producer.error.inspect unless fd

assert('payload did not round-trip') { consumer.read(fd.to_s) == payload }
assert('inherited payload did not restore close-on-exec') do
  IO.new(fd, 'rb', :autoclose => false).close_on_exec?
end
assert('payload is not fully sealed') do
  IO.new(fd, 'rb', :autoclose => false).fcntl(1034) & 15 == 15
end
assert('sealed payload accepted a write') do
  begin
    IO.new(fd, 'wb', :autoclose => false).syswrite('x')
    false
  rescue Errno::EPERM
    true
  end
end

script = 'io = IO.new(ENV.fetch("FD").to_i, "rb", :autoclose => false); io.fcntl(1034)'
pid = Process.spawn(
  { 'FD' => fd.to_s },
  RbConfig.ruby,
  '-e',
  "begin; #{script}; exit 1; rescue Errno::EBADF; exit 0; end",
  { :close_others => false }
)
_, status = Process.waitpid2(pid)
assert('payload descriptor leaked through an unrelated exec') { status.success? }

args = [
  RbConfig.ruby,
  '-e',
  'io = IO.new(ENV.fetch("FD").to_i, "rb", :autoclose => false); exit(io.fcntl(1034) & 15 == 15 ? 0 : 1)',
  { :close_others => true },
]
consumer.preserve_exec!(args)
pid = Process.spawn({ 'FD' => fd.to_s }, *args)
_, status = Process.waitpid2(pid)
assert('payload descriptor did not survive exec') { status.success? }

owner = load_memfd
owned_fd = owner.create(payload)
raise owner.error.inspect unless owned_fd
owner.close!
assert('closed payload descriptor remained open') do
  begin
    IO.new(owned_fd, 'rb', :autoclose => false).fcntl(1034)
    false
  rescue Errno::EBADF
    true
  end
end

rd, wr = IO.pipe
assert('pipe was accepted as a payload') { load_memfd.read(rd.fileno.to_s).nil? }
rd.close
wr.close

puts 'memfd tests passed'
