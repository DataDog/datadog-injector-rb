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
  # TODO: handle '+0' suffix appearing in preview versions

  major, minor, = RUBY_VERSION.split('.')

  "#{major}.#{minor}.0"
end
