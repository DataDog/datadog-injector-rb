require 'fileutils'

# Create the repository as the container user so Git trusts its ownership.
FileUtils.mkdir_p(File.join(__dir__, 'repo'))
FileUtils.cp_r(File.join(__dir__, 'local_git', '.'), File.join(__dir__, 'repo'))

Dir.chdir(File.join(__dir__, 'repo')) do
  system('git', 'init', '--quiet') || abort('Could not initialise Git dependency')
  system('git', 'add', '.') || abort('Could not stage Git dependency')
  system('git', '-c', 'user.name=Test', '-c', 'user.email=test@example.com',
    '-c', 'commit.gpgsign=false', 'commit', '--quiet', '-m', 'Create dependency') || abort('Could not commit Git dependency')
end
