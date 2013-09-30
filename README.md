# mm-tree
[![Build Status](https://travis-ci.org/leifcr/mm-tree.png?branch=devel)](https://travis-ci.org/leifcr/mm-tree)

IMPORTANT NOTE: Current master branch is unstable, and is not recommended for production sites. Due to MM not being actively maintained, a monogid version is in the works.

This is a tree structure for MongoMapper documents that support rational numbers for positioning.
Read about rational numbers in tree structures here: http://arxiv.org/pdf/0806.3115v1.pdf

The reason for the changed implementation to use rational numbers is to be able to query a tree and get the tree structure by sorting on the rational number. It also makes it easy to query parts of a tree as well.

Rational numbers is even better than left/right trees, as you can remove parts of a tree or a node without reordering the entire tree. It is a bit more complicated, but there are some really good benefits.


## Installation

### Using bundler

Latest stable release:

```
gem 'mm-tree'
```

For latest edge version:

```
gem 'mm-tree', :git => 'http://github.com/leifcr/mm-tree.git'
```

This gem *only* supports the following versions:

   * mongomapper >= 0.13
   * ruby >= 2.0
   * rails >= 3.2

_Note: If you are using mongo\_mapper < 0.13, ruby < 2.0 or rails < 3.2 you have to use version 0.1.4.

## Usage

Enable the tree functionality by adding the plugin on your model

```ruby
class Category
  include MongoMapper::Document
  plugin  MongoMapper::Plugins::Tree

  key :name, String
end
```

*Note:* Rational numbers positioning is enabled by default.

This adds one embedded tree_info document (non-changeable) and the following class attributes:

* _tree\_parent\_id_field_ overrides the field used for parent_id (default: parent_id)
* _tree\_search\_class_ expects a Class that is a MongoMapper::Document to be used for search (So you can have one collection with inherited models and trees for each model, not conflicting with each other)
* _tree\_use\_rational\_numbers_ use rational numbers for sorting. set to false if you don't want it.
* _tree\_order_ controls the order if rational numbers aren't used (format :field_name.[asc|desc]), else soriting is by rational numbers.

If you want to use explicit _tree\_order_, you *have to* set _tree\_use\_rational\_numbers_ to false.

## Configuration Examples

Not using rational numbers, sorting by name, and using a different ID field.

```ruby
class Category
  include MongoMapper::Document
  plugin  MongoMapper::Plugins::Tree
  self.tree_parent_id_field      = "my_super_parent_id"
  self.tree_use_rational_numbers = false
  self.tree_order                = :name.asc

  key :name, String
end
```

Using rational numbers, and using search classes to have inherited models in same collection but different trees:

```ruby
class Shape
  include MongoMapper::Document
  plugin  MongoMapper::Plugins::Tree
  self.tree_search_class = Shape

  key :name, String
end

class Circle < Shape
  self.tree_search_class = Circle
end

class Square < Shape
  self.tree_search_class = Square
end
```

Using rational numbers, and using search classes to have inherited models in same collection and same tree:

```ruby
class Shape
  include MongoMapper::Document
  plugin  MongoMapper::Plugins::Tree
  self.tree_search_class = Shape

  key :name, String
end

class Circle < Shape
end

class Square < Shape
end
```

## Example for moving parents

To move a child node from one parent to another you can do either move to a specific rational number, or just set the parent.

Move using parent

```ruby
node_1      = Category.create(:name => "Node 1")
node_1_1    = Category.create(:name => "Node 1.1", :parent => @node_1)
node_2      = Category.create(:name => "Node 2")
node_1_1.parent = node_2
node_1_1.save
node_1_1.parent.name # => "Node 2"
```

Move using rational values (nv/dv)

```ruby
node_1      = Category.create(:name => "Node 1")
node_1_1    = Category.create(:name => "Node 1.1", :parent => @node_1)
node_2      = Category.create(:name => "Node 2")
node_2.set_position(node_1_1.tree_info.nv, node_1_1.tree_info.dv) # move to position of node_1_1
node_2.save
node_2.siblings.first.name # => "Node 1.1"
node_2.parent.name # => "Node 1"
# Node 2 is now in front of Node 1.1 as it has taken node 1.1's place.
```

Check test_order.rb, test_tree.rb and test_search_class.rb for more examples and details on usage.

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Send me a pull request, if you have features you like to see implemented.

## Thanks

_Jakob Vidmar_  (For the original MongoMapper Tree)
_Joel Junström_ (I based this tree on his refactoring of Jakobs MongoMapper Tree)
_MongoMapper devels_ (John Nunemaker, Brandon Keepers, Chris Heald and others)

## Copyright

Original ideas are Copyright Jakob Vidmar and Joel Junström. Please see their github repositories for details
Copyright (c) 2013 Leif Ringstad.
See LICENSE for details.
