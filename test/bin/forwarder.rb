#!/usr/bin/env ruby

conf = ENV['DD_TELEMETRY_FORWARDER_LOG'] || 'stdout'
targets = conf.split(',')
outputs = targets.uniq.map do |t|
  case t
  when 'stdout'
    $stdout
  when 'stderr'
    $stderr
  else
    File.open(t, 'ab')
  end
end

loop do
  data = $stdin.read
  data << "\n" unless data[-1] == "\n"

  outputs.each do |io|
    io.write data
    io.flush
  end

  break if $stdin.eof?
end
