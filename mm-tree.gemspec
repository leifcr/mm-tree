# encoding: UTF-8
require File.expand_path('../lib/version', __FILE__)
Gem::Specification.new do |s|
  s.name           = 'mm-tree'
  s.homepage       = 'http://github.com/leifcr/mm-tree'
  s.summary        = 'Tree structure for MongoMapper'
  s.description    = 'Tree structure for MongoMapper'
  s.require_paths   = ['lib']
  s.authors        = ['Joel Junström', 'Leif Ringstad']
  s.email          = ['joel.junstrom@oktavilla.se']
  s.version        = MongoMapperTree::Version
  s.platform       = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,test}/**/*") + %w[LICENSE README.rdoc]

  s.test_files = Dir.glob("{test}/**/*")

  s.add_dependency 'mongo_mapper', '~> 0.11.0'
  s.add_development_dependency 'shoulda', '~> 2.11.3'
end