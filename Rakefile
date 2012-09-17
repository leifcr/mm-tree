require 'rubygems'
require "bundler/gem_tasks"
require 'bundler/setup'
require 'rake'
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag -a \"v#{MongoMapper::Tree::Version}\""
  sh "git push origin master"
  sh "git push origin v#{MongoMapper::Tree::Version}"
  sh "gem push mm-tree-#{MongoMapper::Tree::Version}.gem"
end