# ruby-version-min: 2.6

if (closed_fd = ENV['DD_TEST_CLOSED_MEMFD'])
  closed = begin
             IO.new(closed_fd.to_i, 'rb', :autoclose => false).fcntl(1034)
             false
           rescue SystemCallError
             true
           end
  puts "injector-probe:memfd_closed=#{closed}"
end

if defined?(Bundler) && ENV['DD_INTERNAL_RUBY_INJECTOR_BUNDLE'] == 'true'
  gemfile_path = Bundler.default_gemfile.to_s
  lockfile_path = Bundler.default_lockfile.to_s
  gemfile_disk = File.read(gemfile_path)
  gemfile_mem = Bundler.read_file(gemfile_path)
  lockfile_disk = File.read(lockfile_path)
  lockfile_mem = Bundler.read_file(lockfile_path)

  ffi = lockfile_mem.lines.grep(/^    ffi/)
  nokogiri = lockfile_mem.lines.grep(/^    nokogiri/)
  fd = ENV['DD_INTERNAL_RUBY_INJECTOR_MEMFD']
  seals = IO.new(fd.to_i, 'rb', :autoclose => false).fcntl(1034) rescue nil

  puts "injector-probe:gemfile_patched=#{gemfile_disk != gemfile_mem}"
  puts "injector-probe:lockfile_patched=#{lockfile_disk != lockfile_mem}"
  puts "injector-probe:gemfile_datadog=#{gemfile_mem.include?('gem "datadog"')}"
  puts "injector-probe:lockfile_datadog=#{lockfile_mem.include?(' datadog ')}"
  puts "injector-probe:datadog_require=#{gemfile_mem =~ /gem \"datadog\".*(?::require\s*=>\s*|require:\s*)\"datadog\/single_step_instrument\"/ ? true : false}"
  puts "injector-probe:ffi_app_version=#{ffi.any? && ffi.all? { |line| line =~ /\(1\.17\.\d+.*\)/ } ? true : false}"
  puts "injector-probe:nokogiri_binary=#{nokogiri.any? && nokogiri.all? { |line| line =~ /\(.*-.*\)/ } ? true : false}"
  puts "injector-probe:memfd_sealed=#{seals && seals & 15 == 15 ? true : false}"
  puts "injector-probe:legacy_env=#{!!(ENV['DD_INTERNAL_RUBY_INJECTOR_GEMFILE_CONTENT'] || ENV['DD_INTERNAL_RUBY_INJECTOR_LOCKFILE_CONTENT'])}"
  puts "injector-probe:bundler_setup_eager=#{!!ENV['BUNDLER_SETUP']}"
  puts "injector-probe:instrumentation_required=#{$LOADED_FEATURES.any? { |path| path.end_with?('/datadog/single_step_instrument.rb') }}"
  puts "injector-probe:gemdeps_selected=#{File.basename(Bundler.default_gemfile.to_s) == 'gem.deps.rb'}"

  if (launch = ENV['DD_TEST_BUNDLE_CHILD']) && ENV['DD_TEST_BUNDLE_CHILD_PHASE'] != 'true'
    ENV['DD_TEST_BUNDLE_CHILD_PHASE'] = 'true'
    script = File.expand_path($0)
    success = case launch
              when 'plain'
                system RbConfig.ruby, script
              when 'nested-bundle-exec'
                system "bundle exec #{RbConfig.ruby} #{script}"
              when 'unbundled'
                Bundler.unbundled_system(
                  {
                    'DD_TEST_BUNDLE_CHILD_PHASE' => 'true',
                    'DD_TEST_CLOSED_MEMFD' => fd,
                  },
                  RbConfig.ruby,
                  script
                )
              end
    raise "child launch failed: #{launch}" unless success
  end
end
