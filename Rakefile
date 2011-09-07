require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = [
    '-c',
    '--format documentation',
    '-r ./spec/spec_helper.rb'
  ]
  t.pattern = 'spec/**/*_spec.rb'
end

desc "open coverage report"
task :coverage do
  system 'rake spec'
  system 'open coverage/index.html'
end

desc "Open development console"
task :console do
  puts "Loading development console..."
  system "irb -I #{File.join('.', 'lib')} -r #{File.join('.', 'lib', 'lrucache')}"
end
