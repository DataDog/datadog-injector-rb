require 'bundler/setup'
require 'paint'

raise 'Datadog is not in the active bundle' unless Gem.loaded_specs.key?('datadog')
raise 'Application gem is not isolated' unless Gem.loaded_specs.fetch('paint').full_gem_path.start_with?(File.join(Dir.pwd, 'vendor/'))

puts 'Isolated application bundle includes Datadog'
