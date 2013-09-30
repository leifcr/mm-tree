# encoding: utf-8

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require "bundler/gem_tasks"
require 'bundler/setup'
require 'rake'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rspec_opts = ['--color']
  end
  task :default => :spec
rescue LoadError
  nil
end

# desc 'Tags version, pushes to remote, and pushes gem'
# task :release => :build do
#   sh "git tag -a \"v#{MongoMapper::Tree::Version}\""
#   sh "git push origin master"
#   sh "git push origin v#{MongoMapper::Tree::Version}"
#   sh "gem push mm-tree-#{MongoMapper::Tree::Version}.gem"
# end

# require 'jeweler'
# Jeweler::Tasks.new do |gem|
#   # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
#   gem.name = "mm-tree"
#   gem.homepage = "https://github.com/leifcr/mm-tree"
#   gem.license = "MIT"
#   gem.summary = %Q{Tree structure for MongoMapper with rational number sorting}
#   gem.description = %Q{Tree structure for MongoMapper with rational number sorting}
#   gem.email = "leifcr@gmail.com"
#   gem.authors = ["Leif Ringstad"]
#   gem.files.exclude [".ruby-*", ".travis.yml"]
#   # dependencies defined in Gemfile
# end
# Jeweler::RubygemsDotOrgTasks.new
