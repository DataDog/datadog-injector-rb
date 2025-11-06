# ruby-version-min: 1.8.7

def self.version_min?(version)
  RUBY_VERSION >= "#{version}."
end

def self.version
  RUBY_VERSION
end

def self.engine
  defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
end

def self.engine_version
  defined?(RUBY_ENGINE_VERSION) ? RUBY_ENGINE_VERSION : RUBY_VERSION
end

def self.platform
  RUBY_PLATFORM
end

def self.api_version
  require 'rbconfig' unless defined?(RbConfig)

  RbConfig::CONFIG['ruby_version']
end
