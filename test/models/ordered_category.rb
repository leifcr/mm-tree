class OrderedCategory
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Tree

  key :name,  String
  key :value, Integer

  self.tree_order = :value.asc
  self.tree_use_rational_numbers = false
end