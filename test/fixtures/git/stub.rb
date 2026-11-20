#!/usr/bin/env ruby

require 'bundler/setup'
require 'local_git'

roots = $LOADED_FEATURES.grep(%r{/bundler(?:\.rb|/(?:setup|cli|version|errors)\.rb)\z}).map do |feature|
  feature.sub(%r{/bundler(?:/.*|\.rb)\z}, '')
end.uniq
raise "Bundler loaded from multiple roots: #{roots.inspect}" unless roots.size == 1

raise 'Git dependency was not loaded' unless LocalGit::VERSION == '1.0.0'
raise 'Datadog is not in the active bundle' unless Gem.loaded_specs.key?('datadog')
raise 'Git dependency is not in the application bundle' unless Gem.loaded_specs.fetch('local_git').full_gem_path.start_with?(File.join(Dir.pwd, 'vendor/'))

puts 'Application Git dependency and Datadog are both available'
