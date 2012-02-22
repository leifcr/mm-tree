require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

desc 'Builds the gem'
task :build do
  sh "gem build mm-tree.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install mm-tree-#{MongoMapperTree::Version}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{MongoMapperTree::Version}"
  sh "git push origin master"
  sh "git push origin v#{MongoMapperTree::Version}"
  sh "gem push mm-tree-#{MongoMapperTree::Version}.gem"
end