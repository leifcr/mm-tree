# encoding: UTF-8
module MongoMapper
  module Plugins
    module Tree
      extend ActiveSupport::Concern

      module ClassMethods
        def roots
          self.where(parent_id_field => nil).sort(tree_order).all
        end

        # get entire tree structure as a hash
        # starting with alll roots
        def tree_as_nested_hash(additional_fields = [], secondary_sort = nil, depth = nil)
          # only query additional fields if asked for, if not, only get parent/child structure.
          # if additional_fields == [], assume all fields?
          fields_arr = Array.new(additional_fields)
          fields_arr << path_field.to_sym
          fields_arr << depth_field.to_sym
          fields_arr << parent_id_field.to_sym

          nested_query = tree_search_class.where(parent_id_field => nil).fields(fields_arr)

          if (secondary_sort != nil)
            nested_query = nested_query.sort(self.depth_field.to_sym.asc, tree_order, secondary_sort)
          else
            nested_query = nested_query.sort(self.depth_field.to_sym.asc, tree_order)
          end

          ret = Hash.new
          nodes = nested_query.all

          #base_depth = nested_query.first.depth
          for single_node in nodes
            if (single_node.depth == 0) # process roots 
              sub_depth = nil if depth.nil?
              sub_depth = depth if !depth.nil?
              ret[single_node._id] = {
                :depth => single_node.depth,
                :path  => single_node.path,
              }
              for add_field in additional_fields
                ret[single_node._id] = ret[single_node._id].merge(Hash[add_field, single_node[add_field]])
              end
              ret[single_node._id] = ret[single_node._id].merge(Hash[:children, single_node.sub_nodes_as_nested_hash(single_node, single_node.descendants, additional_fields, sub_depth)])

            end
          end
          ret
        end # tree_as_nested_hash 

      end # Module ClassMethods

      # 
      def descendants_as_nested_hash(additional_fields = [], secondary_sort = nil, depth = nil)
        # only query additional fields if asked for, if not, only get parent/child structure.
        fields_arr = Array.new(additional_fields) 
        fields_arr << self.path_field.to_sym
        fields_arr << self.depth_field.to_sym
        fields_arr << self.parent_id_field.to_sym

        nested_query = tree_search_class.where(path_field => self._id).fields(fields_arr)

        if (secondary_sort != nil)
          nested_query = nested_query.sort(self.depth_field.to_sym.asc, tree_order, secondary_sort)
        else
          nested_query = nested_query.sort(self.depth_field.to_sym.asc, tree_order)
        end

        ret = Hash.new
        nodes = nested_query.all
        #base_depth = nested_query.first.depth
        for single_node in nodes
          if (single_node.depth == self[depth_field] + 1) # only if we are 1 down from this 
            sub_depth = nil if depth.nil?
            sub_depth = depth-1 if !depth.nil?
            ret[single_node._id] = {
              :depth => single_node.depth,
              :path  => single_node.path,
              #:children => find_sub_nodes(single_node, get_child_nodes_only(single_node, nodes), additional_fields, sub_depth)
            }
            for add_field in additional_fields
              ret[single_node._id] = ret[single_node._id].merge(Hash[add_field, single_node[add_field]])
            end
            ret[single_node._id] = ret[single_node._id].merge(Hash[:children, sub_nodes_as_nested_hash(single_node, nodes, additional_fields, sub_depth)])
          end
        end
        ret
      end # descendants_as_nested_hash

      def tree_search_class
        self.class.tree_search_class
      end

      def will_save_tree
        if parent && self.descendants.include?(parent)
          errors.add(:base, :cyclic)
        end
      end

      def fix_position(opts = {})
        if parent.nil?
          self[parent_id_field] = nil
          self[path_field] = []
          self[depth_field] = 0
        elsif !!opts[:force] || self.changes.include?(parent_id_field)
          @_will_move = true
          self[path_field]  = parent[path_field] + [parent._id]
          self[depth_field] = parent[depth_field] + 1
        end
      end

      def fix_position!
        fix_position(:force => true)
        save
      end

      def root?
        self[parent_id_field].nil?
      end

      def root
        self[path_field].first.nil? ? self : tree_search_class.find(self[path_field].first)
      end

      def ancestors
        return [] if root?
        tree_search_class.find(self[path_field])
      end

      def self_and_ancestors
        ancestors << self
      end

      def siblings
        tree_search_class.where({
          :_id => { "$ne" => self._id },
          parent_id_field => self[parent_id_field]
        }).sort(tree_order).all
      end

      def self_and_siblings
        tree_search_class.where({
          parent_id_field => self[parent_id_field]
        }).sort(tree_order).all
      end

      def children
        tree_search_class.where(parent_id_field => self._id).sort(depth_field.to_sym.asc, tree_order).all
      end

      def descendants
        return [] if new_record?
        tree_search_class.where(path_field => self._id).sort(depth_field.to_sym.asc, tree_order).all
      end

      def self_and_descendants
        [self] + self.descendants
      end

      def is_ancestor_of?(other)
        other[path_field].include?(self._id)
      end

      def is_or_is_ancestor_of?(other)
        (other == self) or is_ancestor_of?(other)
      end

      def is_descendant_of?(other)
        self[path_field].include?(other._id)
      end

      def is_or_is_descendant_of?(other)
        (other == self) or is_descendant_of?(other)
      end

      def is_sibling_of?(other)
        (other != self) and (other[parent_id_field] == self[parent_id_field])
      end

      def is_or_is_sibling_of?(other)
        (other == self) or is_sibling_of?(other)
      end

      def move_children
        if @_will_move
          @_will_move = false
          self.children.each do |child|
            child.fix_position!
          end
          @_will_move = true
        end
      end

      def destroy_descendants
        tree_search_class.destroy(self.descendants.map(&:_id))
      end

      included do
        # Tree search class will be used as the base from which to
        # find tree objects. This is handy should you have a tree of objects that are of different types, but
        # might be related through single table inheritance.
        #
        #   self.tree_search_class = Shape
        #
        # In the above example, you could have a working tree ofShape, Circle and Square types (assuming
        # Circle and Square were subclasses of Shape). If you want to do the same thing and you don't provide
        # tree_search_class, nesting mixed types will not work.
        class_attribute :tree_search_class
        self.tree_search_class ||= self

        class_attribute :parent_id_field
        self.parent_id_field ||= "parent_id"

        class_attribute :path_field
        self.path_field ||= "path"

        class_attribute :depth_field
        self.depth_field ||= "depth"

        class_attribute :tree_order

        key parent_id_field, ObjectId
# temporary removing index until figuring out how to fix it...        
#        key path_field, Array, :default => [], :index => true
        key path_field, Array, :default => []
        key depth_field, Integer, :default => 0

        belongs_to :parent, :class => tree_search_class

        validate         :will_save_tree
        after_validation :fix_position
        after_save       :move_children
        before_destroy   :destroy_descendants
      end

      def sub_nodes_as_nested_hash(node, nodes, additional_fields = [], depth = nil)
        
        # only work through child nodes. Will speed up iteration...
        nodes = get_child_nodes_only(node, nodes)

        return {} if (nodes.nil? || node.nil?)
        return {} if ((depth != nil) && (depth <= 0)) # shouldn't dig further down

        ret = Hash.new

        sub_depth = nil     if depth.nil?
        sub_depth = depth-1 if !depth.nil?

        for sub_node in nodes
          if ((sub_node.depth == (node.depth + 1 )) && (sub_node.parent_id == node.id))
            ret[sub_node._id] = {
              :depth => sub_node.depth,
              :path =>  sub_node.path,
            }
            for add_field in additional_fields
              ret[sub_node._id] = ret[sub_node._id].merge(Hash[add_field, sub_node[add_field]])
            end
            ret[sub_node._id] = ret[sub_node._id].merge(Hash[:children, sub_nodes_as_nested_hash(sub_node, nodes, additional_fields, sub_depth)])
          end
        end
        ret
      end # sub_nodes_as_nested_hash  

    private
      def get_child_nodes_only(node, nodes)
        return nil if (node.nil? || nodes.nil?)
        return nil if (nodes.count <= 0)

        ret_nodes = Array.new(nodes)
        for single_node in nodes
            ret_nodes.delete(single_node) if !(single_node.path.include?(node.id))
        end

        return nil if (ret_nodes.count <= 0 )

        ret_nodes
      end # get_child_nodes_only

    end # Module Tree
  end # Module Plugins
end # Module MongoMapper
