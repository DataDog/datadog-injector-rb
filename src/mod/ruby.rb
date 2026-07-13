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

# Whether this is a prerelease build (preview, rc, or dev) rather than a
# final release. Final releases have RUBY_PATCHLEVEL >= 0; prereleases use -1.
# Version-agnostic: e.g. Ruby 3.5 only ever shipped as previews.
def self.prerelease?
  defined?(RUBY_PATCHLEVEL) && RUBY_PATCHLEVEL == -1
end

def self.api_version
  require 'rbconfig' unless defined?(RbConfig)

  RbConfig::CONFIG['ruby_version']
end
