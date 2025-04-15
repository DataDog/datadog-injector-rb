require 'bundler/setup'

puts "stub:hot #{ENV['BUNDLE_DEPLOYMENT'].inspect} #{Bundler.frozen_bundle?} #{Bundler.settings[:deployment]}"
