#!/usr/bin/env ruby

require 'bundler' unless defined?(Bundler)
Bundler.setup
require 'local_git'

raise 'Git dependency was not loaded' unless LocalGit::VERSION == '1.0.0'
raise 'Datadog is not in the active bundle' unless Gem.loaded_specs.key?('datadog')
raise 'Git dependency is not in the application bundle' unless Gem.loaded_specs.fetch('local_git').full_gem_path.start_with?(File.join(Dir.pwd, 'vendor/'))

puts 'Application Git dependency and Datadog are both available'
