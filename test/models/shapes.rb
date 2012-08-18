class Shape
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Tree
  self.tree_search_class = Shape

  key :name, String
end

class Circle < Shape; end
class Square < Shape; end

class Triangle < Shape
  self.tree_search_class = Triangle
end

class Cube < Shape
  self.tree_search_class = Cube
end
