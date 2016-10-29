require 'rake'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

task default: [:rubocop_dev, :spec]
task ci: [:rubocop, :spec]

task :clean do
  sh 'rm -frv pkg'
end

task :rubocop do
  sh 'rubocop'
end

task :rubocop_dev do
  sh 'rubocop --auto-gen-config'
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = Dir.glob('spec/**/*_spec.rb')
end
