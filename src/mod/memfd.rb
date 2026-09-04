# ruby-version-min: 1.8.7

MAGIC = "DDRBMFD\x01"
HEADER_SIZE = MAGIC.bytesize + 24
MAX_PAYLOAD_SIZE = 64 * 1024 * 1024

MFD_CLOEXEC = 0x0001
MFD_ALLOW_SEALING = 0x0002

F_ADD_SEALS = 1033
F_GET_SEALS = 1034
F_SEAL_SEAL = 0x0001
F_SEAL_SHRINK = 0x0002
F_SEAL_GROW = 0x0004
F_SEAL_WRITE = 0x0008
REQUIRED_SEALS = F_SEAL_SEAL | F_SEAL_SHRINK | F_SEAL_GROW | F_SEAL_WRITE

class << self
  attr_reader :error

  def create(payload)
    @error = nil
    if ENV['DD_INTERNAL_RUBY_INJECTOR_DISABLE_MEMFD'] == 'true'
      @error = RuntimeError.new('memfd transport is disabled')
      return
    end

    data = encode(payload)
    return unless data

    fd = Kernel.send(:syscall, syscall_number, 'dd-ruby-injector', MFD_CLOEXEC | MFD_ALLOW_SEALING)
    io = IO.new(fd, 'w+b')

    begin
      written = io.write(data)
      raise IOError, 'short write to memfd' unless written == data.bytesize

      io.flush
      io.fcntl(F_ADD_SEALS, REQUIRED_SEALS)
      raise IOError, 'memfd is not sealed' unless sealed?(io)

      @io.close if @io && !@io.closed?
      @io = io
      fd
    rescue Exception
      io.close unless io.closed?
      raise
    end
  rescue StandardError => e
    @error = e
    nil
  end

  def read(value)
    @error = nil
    return unless value && value =~ /\A\d+\z/

    io = IO.new(value.to_i, 'rb', :autoclose => false)
    raise IOError, 'descriptor is not a sealed regular file' unless io.stat.file? && sealed?(io)
    raise IOError, 'memfd payload is too large' if io.stat.size > MAX_PAYLOAD_SIZE

    data = io.pread(io.stat.size, 0)
    payload = decode(data)
    return unless payload

    @io = io
    payload
  rescue StandardError => e
    @error = e
    nil
  end

  def matches?(payload, gemfile, lockfile)
    return false unless payload && gemfile && lockfile

    gemfile_path = File.expand_path(gemfile.to_s)
    lockfile_path = File.expand_path(lockfile.to_s)

    payload[:gemfile_path] == gemfile_path &&
      payload[:lockfile_path] == lockfile_path &&
      file_content(gemfile_path) == payload[:original_gemfile_content] &&
      file_content(lockfile_path) == payload[:original_lockfile_content]
  rescue StandardError
    false
  end

  def preserve_exec!(args)
    return args unless @io && !@io.closed?

    options = args.last.is_a?(Hash) ? args.pop.dup : {}
    options[@io.fileno] = @io.fileno
    args << options
  end

  def fd
    @io.fileno if @io && !@io.closed?
  end

  private

  def syscall_number
    case RUBY_PLATFORM
    when /x86_64-linux/
      319
    when /aarch64-linux/
      279
    else
      raise RuntimeError, "memfd_create is unsupported on #{RUBY_PLATFORM}"
    end
  end

  def encode(payload)
    parts = [
      File.expand_path(payload[:gemfile_path].to_s),
      File.expand_path(payload[:lockfile_path].to_s),
      payload[:gemfile_content].to_s,
      payload[:lockfile_content].to_s,
      payload[:original_gemfile_content].to_s,
      payload[:original_lockfile_content].to_s,
    ].map { |part| binary(part) }

    size = HEADER_SIZE + parts.inject(0) { |sum, part| sum + part.bytesize }
    raise ArgumentError, 'memfd payload is too large' if size > MAX_PAYLOAD_SIZE

    binary(MAGIC) + parts.map { |part| part.bytesize }.pack('N6') + parts.join
  end

  def decode(data)
    return unless data && data.bytesize >= HEADER_SIZE
    return unless data.byteslice(0, MAGIC.bytesize) == binary(MAGIC)

    lengths = data.byteslice(MAGIC.bytesize, 24).unpack('N6')
    return unless HEADER_SIZE + lengths.inject(0) { |sum, length| sum + length } == data.bytesize

    offset = HEADER_SIZE
    parts = lengths.map do |length|
      part = data.byteslice(offset, length)
      offset += length
      part
    end

    {
      :gemfile_path => text(parts[0]),
      :lockfile_path => text(parts[1]),
      :gemfile_content => text(parts[2]),
      :lockfile_content => text(parts[3]),
      :original_gemfile_content => parts[4],
      :original_lockfile_content => parts[5],
    }
  end

  def sealed?(io)
    io.fcntl(F_GET_SEALS) & REQUIRED_SEALS == REQUIRED_SEALS
  end

  def binary(string)
    string = string.dup
    string.force_encoding(Encoding::BINARY) if defined?(Encoding)
    string
  end

  def text(string)
    string.force_encoding(Encoding::UTF_8) if defined?(Encoding)
    string
  end

  def file_content(path)
    File.open(path, 'rb') { |file| file.read }
  end
end
