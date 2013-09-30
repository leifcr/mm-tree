class Category
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Tree

  self.tree_use_rational_numbers = false

  key :name, String
  timestamps!
end