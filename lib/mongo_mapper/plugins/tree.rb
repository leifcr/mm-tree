# encoding: UTF-8
module MongoMapper
  module Plugins
    module Tree
      @@_disable_timestamp_count = 0
      extend ActiveSupport::Concern

      module ClassMethods

        ##
        # Get the roots for the collection / document type
        #
        # @return [MongoMapper::Document] Root documents that are roots for the document type.
        #
        def roots
          self.where(tree_parent_id_field => nil).sort(tree_sort_order()).all
        end

        ##
        # Get the tree sort order
        #
        # TODO: move to rational numbering when implemented!
        #
        # @return [String] The tree sort order
        #
        def tree_sort_order
          if !tree_use_rational_numbers
            "#{tree_order} #{tree_depth_field}"
          else
            tree_nv_div_dv_field.asc
          end
        end

      end # Module ClassMethods


      ##
      # Initializer for the Tree.
      #
      # @return [undefined]
      # def initialize(*args)
      #   super
      # end


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
        #
        #
        # An index for path_field and parent_id_field is recommended for faster queries.
        #
        #

        class_attribute :tree_use_rational_numbers
        self.tree_use_rational_numbers ||= true

        class_attribute :tree_search_class
        self.tree_search_class     ||= self

        class_attribute :tree_destroy_descendants
        self.tree_destroy_descendants     ||= true

        # The parent ID of the document
        class_attribute :tree_parent_id_field
        self.tree_parent_id_field  ||= :tree_parent_id
        key tree_parent_id_field, ObjectId

        # The current depth of the document
        class_attribute :tree_depth_field
        self.tree_depth_field ||= :tree_depth
        key tree_depth_field, Integer, :default => 0

        # The given path of the object, starting with first ancestor.
        class_attribute :tree_path_field
        self.tree_path_field  ||= :tree_path
        key tree_path_field, Array, :typecast => 'ObjectId'

        # The ordering for the tree. (Will have no effect if rational numbers are used)
        class_attribute :tree_order

        belongs_to :parent, :class => tree_search_class, :foreign_key => tree_parent_id_field

        validate          :verify_parent_is_not_descendant
        validate          :verify_valid_search_class

        after_validation do
          run_callbacks :update_path do
            update_path
          end
        end

        after_save do
          run_callbacks :rearrange_children do
            rearrange_children
          end
        end

        #TODO: TRIGGER NV/DV from callbacks? Must figure out how to MANUALLY trigger around callback at correct point!
#        after_save        :rearrange_children

        before_destroy    :destroy_or_remove_from_descendants

        # Rearrange callbacks
        define_model_callbacks :update_path, :only => [:before, :after]
        define_model_callbacks :rearrange_children, :only => [:before, :after]
      end

      # def enable_debug_output
      #   @@_debug_output = true
      # end

      # def debug_enabled?
      #   !!@@_debug_output
      # end

      ##
      # Get the search class for the document type.
      # Do not set this if you are using polymorphic associtations
      #
      # @return [String] The search class for the documents.
      def tree_search_class
        self.class.tree_search_class
      end

      ##
      # Verify that this does not have the parent as a descendant (We do not want cyclic trees)
      #
      def verify_parent_is_not_descendant
        unless self[tree_parent_id_field].nil?
          errors.add(:base, I18n.t(:cyclic, :scope => [:mongo_mapper, :errors, :messages, :tree])) if self.descendants.include?(parent)
        end
      end

      ##
      # Verify that the search class is valid
      #
      def verify_valid_search_class
        if parent
          if (parent.tree_search_class != self.tree_search_class)
            errors.add(:base,  I18n.t(:search_class_mismatch, { \
                :parent_search_class => parent.class.tree_search_class, \
                :node_search_class => self.class.tree_search_class, \
                :scope => [:mongo_mapper, :errors, :messages, :tree]}))
          end
        end
      end

      ##
      # Update the path
      #
      # @param [Hash] add {force: true} to force update of the path
      #
      # @return [undefined]
      def update_path(opts = {})
        if parent.nil?
          self[tree_parent_id_field] = nil
          self[tree_path_field]      = []
          self[tree_depth_field]     = 0
        elsif !!opts[:force] || self.changes.include?(tree_parent_id_field)
          self[tree_path_field]  = parent[tree_path_field] + [parent._id]
          self[tree_depth_field] = parent[tree_depth_field] + 1
        end
        rearrange_children! if self.changes.include?(tree_parent_id_field)
        true
      end

      ##
      # Force update of the tree path
      #
      # @return [undefined]
      def update_path!
        update_path(:force => true)
      end

      ##
      # Is this object a root?
      #
      # @return [Boolean] true for root, else false
      def root?
        self[tree_parent_id_field].nil?
      end

      ##
      # Return the root document for the document (Top-most parent)
      #
      # @return [MongoMapper::Document] The root document
      def root
        self[tree_parent_id_field].nil? ? self : tree_search_class.find(self[tree_path_field].first)
      end

      ##
      # Get the ancestors of the document
      #
      # @return [Array] An Array of the ancestors of the document as MongoMapper::Document
      def ancestors
        return [] if root?
        tree_search_class.find(self[tree_path_field])
      end

      ##
      # Get ancestors and self
      #
      # @return [Array] An Array of the self + ancestors of the document as MongoMapper::Document
      def self_and_ancestors
        ancestors << self
      end

      ##
      # Does the document have any siblings?
      #
      # @return [Integer] The number of siblings
      def has_siblings?
        tree_search_class.where(:_id => { "$ne" => self._id }) \
                         .where(tree_parent_id_field => self[tree_parent_id_field]) \
                         .sort(self.class.tree_sort_order()).count
      end

      ##
      # Get all the siblings for the document as an Array
      #
      # @return [Array] An Array of the siblings of the document as MongoMapper::Document
      def siblings
        tree_search_class.where({
          :_id => { "$ne" => self._id },
          tree_parent_id_field => self[tree_parent_id_field]
        }).sort(self.class.tree_sort_order()).all
      end

      ##
      # All the siblings + self for the document as an Array
      #
      # @return [Array] An Array of the siblings + self of the document as MongoMapper::Document
      def self_and_siblings
        tree_search_class.where({
          tree_parent_id_field => self[tree_parent_id_field]
        }).sort(self.class.tree_sort_order()).all
      end

      ##
      # Returns if the document has any children
      #
      # @return [Boolean] true if the document has children, else false
      def children?
        return false if ((self.children == nil) || (self.children == []))
        return true
      end

      ##
      # Get the direct children of the document
      #
      # @return [Array] An Array of the direct children of the document as MongoMapper::Document
      def children
        tree_search_class.where(tree_parent_id_field => self._id).sort(self.class.tree_sort_order()).all
      end

      ##
      # Get the descendants of the document
      #
      # @return [Array] An Array of the the descendants of the document as MongoMapper::Document
      def descendants
        return [] if new_record?
        tree_search_class.where(tree_path_field => self._id).sort(self.class.tree_sort_order()).all
      end

      ##
      # Get the self + descendants of the document
      #
      # @return [Array] An Array of the the self + descendants of the document as MongoMapper::Document
      def self_and_descendants
        [self] + self.descendants
      end

      ##
      # Check if this is a ancestor of another document
      #
      # @param [MongoMapper::Document] a MongoMapper::Document that is part of the tree structure
      #
      # @return [Boolean] true if it is an ancestor of the other document
      def is_ancestor_of?(other)
        other[tree_path_field].include?(self._id)
      end

      ##
      # Check if this is a ancestor of another document or if this is the "other"
      #
      # @param [MongoMapper::Document] a MongoMapper::Document that is part of the tree structure
      #
      # @return [Boolean] true if it is an ancestor of the other document or other is this document
      def is_or_is_ancestor_of?(other)
        (other == self) or is_ancestor_of?(other)
      end

      ##
      # Check if this is a descendant of another document
      #
      # @param [MongoMapper::Document] a MongoMapper::Document that is part of the tree structure
      #
      # @return [Boolean] true if other is a descendant of the document
      def is_descendant_of?(other)
        self[tree_path_field].include?(other._id)
      end

      ##
      # Check if this is a descendant of another document or if this is the "other"
      #
      # @param [MongoMapper::Document] a MongoMapper::Document that is part of the tree structure
      #
      # @return [Boolean] true if other is a descendant of the document or if other is the document
      def is_or_is_descendant_of?(other)
        (other == self) or is_descendant_of?(other)
      end

      ##
      # Check if this is a sibling of another document
      #
      # @param [MongoMapper::Document] a MongoMapper::Document that is part of the tree structure
      #
      # @return [Boolean] true if other is a sibling of the document
      def is_sibling_of?(other)
        (other != self) and (other[tree_parent_id_field] == self[tree_parent_id_field])
      end

      ##
      # Check if this is a sibling of another document or if this is the "other"
      #
      # @param [MongoMapper::Document] a MongoMapper::Document that is part of the tree structure
      #
      # @return [Boolean] true if other is a sibling of the document or if other is the document
      def is_or_is_sibling_of?(other)
        (other == self) or is_sibling_of?(other)
      end

      ##
      # Rearrange children if this document has been moved
      #
      # @return [undefined]
      def rearrange_children
        if rearrange_children?
          self.disable_timestamp_callback()
          self.children.each do |child|
            child.update_path!
            child.save
            # child.reload # might not need to reload?
          end
          self.enable_timestamp_callback()
        end
        @rearrange_children = false
        true
      end


      ##
      # Destroy descendants of this document or remove self as ancestor of descendants
      # Callback upon on_destroy
      #
      # @return [undefined]
      def destroy_or_remove_from_descendants
        if !!self.tree_destroy_descendants
          destroy_descendants
        else
          remove_from_descendants
        end
      end

      ##
      # Destroy the descendants of this document
      #
      # @return [undefined]
      def destroy_descendants
        return if self.descendants.empty?
        tree_search_class.destroy(self.descendants.map(&:_id))
      end

      ##
      # Remove this parent on all the descendants
      #
      # @return [undefined]
      def remove_from_descendants
        # TODO
      end

      ##
      # Forces rearranging of all children after next save
      #
      # @return [undefined]
      def rearrange_children!
        @rearrange_children = true
      end

      ##
      # Will the children be rearranged after next save?
      #
      # @return [Boolean] Whether the children will be rearranged
      def rearrange_children?
        !!@rearrange_children
      end

      ##
      # Disable the timestamps for the document type, and increase the disable count
      # Will only disable once, even if called multiple times
      #
      # @return [undefined]
      def disable_timestamp_callback
        if self.respond_to?("updated_at")
          self.class.skip_callback(:save, :before, :update_timestamps ) if @@_disable_timestamp_count == 0
          @@_disable_timestamp_count += 1
        end
      end

      ##
      # Enable the timestamps for the document type, and decrease the disable count
      # Will only enable once, even if called multiple times
      #
      # @return [undefined]
      def enable_timestamp_callback
        if self.respond_to?("updated_at")
          @@_disable_timestamp_count -= 1
          self.class.set_callback(:save, :before, :update_timestamps ) if @@_disable_timestamp_count == 0
        end
      end

    private

    end # Module Tree
  end # Module Plugins
end # Module MongoMapper
