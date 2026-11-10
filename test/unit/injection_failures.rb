# ruby-version-min: 2.6

if RUBY_VERSION.to_f < 2.6 || !Process.respond_to?(:fork)
  puts 'Injection failure routing requires Ruby 2.6+ with fork'
  exit
end

require 'rubygems'
require 'tmpdir'
require 'fileutils'
require 'pathname'
require File.expand_path('../support/modules', File.dirname(__FILE__))

# Control Bundler failures while exercising the actual injector and isolation boundary.
module Bundler
  VERSION = '2.6.0'
  class GemNotFound < StandardError; end
  class SolveFailure < StandardError; end
  class << self
    attr_accessor :failure
    def settings; self; end
    def temporary(options); yield; end
    def read_file(path); File.read(path); end
  end

  class LockfileParser
    def initialize(contents); end
    def specs; []; end
  end

  class Dsl
    def eval_gemfile(path)
      raise Errno::EACCES if Bundler.failure == :eval
    end

    def dependencies; []; end
    def to_definition(path, options); Definition.new; end
  end

  class Definition
    def specs
      raise SolveFailure, 'original conflict' if Bundler.failure == :original
      []
    end

    def sources; self; end
    def local_only!; end
    def resolve
      raise GemNotFound, 'injected dependency unavailable' if Bundler.failure == :injected
      raise NoMethodError, 'unexpected resolver error' if Bundler.failure == :unexpected
      []
    end

    def lock
      raise Errno::ENOSPC if Bundler.failure == :lock
    end
  end

  class Injector
    def initialize(deps)
      @deps = deps
      @options = {}
    end

    def build_gem_lines(conservative); ''; end
    def append_to(path, lines)
      raise Errno::EROFS if Bundler.failure == :append
    end
  end
end

module InjectionFailuresTest
  Injector = TestModules.import('injector')
  class << Injector::BUNDLER
    def require!(feature = 'bundler'); end
  end

  def self.run
    previous = ENV['DD_INTERNAL_RUBY_INJECTOR']
    Dir.mktmpdir do |path|
      File.open(File.join(path, 'Gemfile'), 'w') { |f| f.write('') }
      File.open(File.join(path, 'Gemfile.lock'), 'w') { |f| f.write('') }
      context = {
        :inject => { :ruby => { :package => { :gem_home => path, :lockfile => File.join(path, 'Gemfile.lock') } } },
        :bundler => { :bundle_path => path, :gemfile => File.join(path, 'Gemfile'), :lockfile => File.join(path, 'Gemfile.lock') },
        :fs => { :target => path },
      }

      [
        [:original, 'bundler.inject.resolve.original.dependency_conflict', 'Bundler::SolveFailure'],
        [:injected, 'bundler.inject.resolve.injected.missing_gem', 'Bundler::GemNotFound'],
        [:unexpected, 'bundler.inject.resolve.injected.unknown', 'NoMethodError'],
        [:eval, 'bundler.inject.gemfile.eval.permission_denied', 'Errno::EACCES'],
        [:append, 'bundler.inject.gemfile.write.read_only', 'Errno::EROFS'],
        [:lock, 'bundler.inject.lockfile.write.no_space', 'Errno::ENOSPC'],
      ].each do |failure, reason, type|
        Bundler.failure = failure
        TestModules.assert_equal([nil, reason, type], Injector.call(context))
      end

      context[:fs][:target] = File.join(path, 'missing-directory')
      TestModules.assert_equal([nil, 'fs.write.missing_file', 'Errno::ENOENT'], Injector.call(context))
    end
    puts 'Injection failures: original/injected resolution, files, and unexpected errors passed'
  ensure
    previous ? ENV['DD_INTERNAL_RUBY_INJECTOR'] = previous : ENV.delete('DD_INTERNAL_RUBY_INJECTOR')
  end
end

InjectionFailuresTest.run
