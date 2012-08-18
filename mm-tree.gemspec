# encoding: UTF-8
require File.expand_path('../lib/version', __FILE__)
Gem::Specification.new do |s|
  s.name           = 'mm-tree'
  s.homepage       = 'http://github.com/leifcr/mm-tree'
  s.summary        = 'Tree structure for MongoMapper'
  s.description    = 'Tree structure for MongoMapper with rational number sorting'
  s.require_paths  = ['lib']
  s.authors        = ['Leif Ringstad']
  s.email          = ['leifcr@gmail.com']
  s.version        = MongoMapper::Tree::Version
  s.platform       = Gem::Platform::RUBY
  s.files          = Dir.glob("{lib,test}/**/*") + %w[LICENSE README.rdoc]

  s.test_files = Dir.glob("{test}/**/*")

  s.add_dependency 'mongo_mapper', '~> 0.11.2'
end