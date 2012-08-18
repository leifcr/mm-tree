require 'pp'
# encoding: UTF-8
module MongoMapper
  module Plugins
    module Tree
      extend ActiveSupport::Concern


      module ClassMethods

        def roots
          self.where(tree_parent_id_field => nil).sort(tree_sort_order()).all
        end

        def position_from_nv_dv(nv, dv)
          anc_tree_keys = ancestor_tree_keys(nv, dv)
          (nv - anc_tree_keys[:nv]) / anc_tree_keys[:snv]
        end

        # returns ancestor nv, dv, snv, sdv values as hash
        def ancestor_tree_keys(nv,dv)
          numerator = nv
          denominator = dv
          ancnv = 0
          ancdv = 1
          ancsnv = 1
          ancsdv = 0
          rethash = {:nv => ancnv, :dv => ancdv, :snv => ancsnv, :sdv => ancsdv}
          # make sure we break if we get root values! (numerator == 0 + denominator == 0)
          #max_levels = 10
          while ((ancnv < nv) && (ancdv < dv)) && ((numerator > 0) && (denominator > 0))# && (max_levels > 0)
            #max_levels -= 1
            div = numerator / denominator
            mod = numerator % denominator
            # set return values to previous values, as they are the parent values
            rethash = {:nv => ancnv, :dv => ancdv, :snv => ancsnv, :sdv => ancsdv}

            ancnv = ancnv + (div * ancsnv)
            ancdv = ancdv + (div * ancsdv)
            ancsnv = ancnv + ancsnv
            ancsdv = ancdv + ancsdv

            numerator = mod
            if (numerator != 0)
              denominator = denominator % mod
              if denominator == 0
                denominator = 1
              end
            end
          end
          return rethash
        end #get_ancestor_keys(nv,dv)

        def tree_sort_order
          if !tree_use_rational_numbers
            "#{tree_order} #{tree_info.depth.asc}" 
          else
            "tree_info.nv_div_dv.asc"
          end
        end

      end # Module ClassMethods

      def initialize(*args)
        @_will_move = false
        @_set_nv_dv = false
        if (self.tree_info == nil)
          self.tree_info = TreeInfo.new
        end
        super
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

        class_attribute :tree_parent_id_field
        self.tree_parent_id_field ||= "parent_id"

        class_attribute :tree_use_rational_numbers
        self.tree_use_rational_numbers ||= true

        class_attribute :tree_order

        key tree_parent_id_field, ObjectId
        one :tree_info
# 
#       An index for path field, left_field and right_field is recommended for faster queries.

        belongs_to :parent, :class => tree_search_class

# FIX VALIDATIONS... this is messy!
        validate          :will_save_tree
        
        before_validation :set_nv_dv_if_missing

        after_validation  :update_tree_info
        after_save        :move_children
        before_destroy    :destroy_descendants
      end

      def tree_search_class
        self.class.tree_search_class
      end

      def will_save_tree
        if parent && self.descendants.include?(parent)
          errors.add(:base, :cyclic)
        end
        if (self.tree_info.changes.include?("nv") && self.tree_info.changes.include?("dv") && self.changes.include?(tree_parent_id_field))
          if !correct_parent?(self.tree_info.nv, self.tree_info.dv)
            errors.add(:base, :incorrect_parent_nv_dv)
          end
        end
      end

      def update_tree_info
        update_path();
        update_nv_dv();
      end

      def update_path(opts = {})
        if parent.nil?
          self[tree_parent_id_field] = nil
          self.tree_info.path = []
          self.tree_info.depth = 0
        elsif !!opts[:force] || self.changes.include?(tree_parent_id_field)
          @_will_move = true
          self.tree_info.path  = parent.tree_info.path + [parent._id] 
          self.tree_info.depth = parent.tree_info.depth + 1
        end
      end

      def update_path!
        update_path(:force => true)
      end

      def set_position(nv, dv)
        self.tree_info.nv = nv
        self.tree_info.dv = dv
      end

    # TODO: what if we move parent without providing NV/DV??? NEED TO SUPPORT THAT AS WELL!
    # Should calculate next free nv/dv and set that if parent has changed. (set values to "missing and call missing function should work")
      def update_nv_dv(opts = {})
        return if !tree_use_rational_numbers
        if @_set_nv_dv == true
          @_set_nv_dv = false
          return
        end
        # if changes include both parent_id, tree_info.nv and tree_info.dv, 
        # checking in validatioon that the parent is correct.
        # if change is only nv/dv, check if parent is correct, move it...
        if (self.tree_info.changes.include?("nv") && self.tree_info.changes.include?("dv"))
          self.move_nv_dv(self.tree_info.nv, self.tree_info.dv)
        elsif (self.changes.include?(tree_parent_id_field)) || opts[:force]
          # only changed parent, needs to find next free position
          # use function for "missing nv/dv"
          # TODO CHECK THIS!!!! might only need self.has_siblings? instead of + 1
          new_keys = self.next_keys_available(self[tree_parent_id_field], (self.has_siblings? + 1)) if !opts[:position]
          new_keys = self.next_keys_available(self[tree_parent_id_field], (opts[:position] + 1)) if opts[:position]
          self.move_nv_dv(new_keys[:nv], new_keys[:dv])
        end
      end

      def update_nv_dv!(opts = {})
        update_nv_dv({:force => true}.merge(opts))
      end

      # sets initial nv, dv, snv and sdv values
      def set_nv_dv_if_missing
        return if !tree_use_rational_numbers
        if (self.tree_info.nv == 0 || self.tree_info.dv == 0 )
          new_keys = self.next_keys_available(self[tree_parent_id_field], (self.has_siblings? + 1) )
          self.tree_info.nv = new_keys[:nv]
          self.tree_info.dv = new_keys[:dv]
          self.tree_info.snv = new_keys[:snv]
          self.tree_info.sdv = new_keys[:sdv]
          self.tree_info.nv_div_dv = Float(new_keys[:nv]/Float(new_keys[:dv]))
          @_set_nv_dv = true
        end
      end


      # if conflcting item on new position, shift all siblings right and insertg
      # can force move without updating conflicting siblings
      def move_nv_dv(nv, dv, opts = {})
        return if !tree_use_rational_numbers
#        return
        # nv_div_dv = Float(nv)/Float(dv)
        # find nv_div_dv?
        position = self.class.position_from_nv_dv(nv, dv)
        if !self.root?
          anc_keys = self.class.ancestor_tree_keys(nv, dv)
          rnv = anc_keys[:nv] + ((position + 1) * anc_keys[:snv])
          rdv = anc_keys[:dv] + ((position + 1) * anc_keys[:sdv])
        else
          rnv = position + 1
          rdv = 1
        end

        # don't check for conflict if forced move
        if (!opts[:ignore_conflict])
          conflicting_sibling = tree_search_class.where("tree_info.nv" => nv).where("tree_info.dv" => dv).first
          if (conflicting_sibling != nil) 
            self.disable_timestamp_callback()
            # find nv/dv to the right of conflict
            # find position/count for this item
            next_keys = conflicting_sibling.next_sibling_keys
            conflicting_sibling.set_position(next_keys[:nv], next_keys[:dv])
            conflicting_sibling.save
            self.enable_timestamp_callback()
          end
        end

        # shouldn't be any conflicting sibling now...
        self.tree_info.nv = nv
        self.tree_info.dv = dv
        self.tree_info.snv = rnv
        self.tree_info.sdv = rdv
        self.tree_info.nv_div_dv = Float(self.tree_info.nv)/Float(self.tree_info.dv)
        # as this is triggered from after_validation, save should be triggered by the caller.
      end
      # change this require ancestor data + position, 
      # next position can be found using: self.has_siblings? + 1
      # as when moving children, the sibling_count won't work
      def next_keys_available(parent_id, position)
        _parent = tree_search_class.where(:_id => parent_id).first
        _parent = nil if ((_parent.nil?) || (_parent == []))
        ancnv = 0
        ancsnv = 1
        ancdv = 1
        ancsdv = 0
        if _parent != nil
          ancnv  = _parent.tree_info.nv
          ancsnv = _parent.tree_info.snv
          ancdv  = _parent.tree_info.dv
          ancsdv = _parent.tree_info.sdv
        end
        if (position == 0) && (_parent.nil?)
          rethash = {:nv => 1, :dv => 1, :snv => 2, :sdv => 1}
        else 
          # get values from sibling_count
          _nv = ancnv + (position * ancsnv)
          _dv = ancdv + (position * ancsdv)
          rethash = {
            :nv => _nv,
            :dv => _dv,
            :snv => ancnv + ((position + 1) * ancsnv),
            :sdv => ancdv + ((position + 1) * ancsdv)
          }
        end
        rethash
      end

      def next_sibling_keys
        next_keys_available(self[tree_parent_id_field], self.class.position_from_nv_dv(self.tree_info.nv, self.tree_info.dv) +1)
      end

      # to save queries, this will calculate ancestor tree keys instead of query them
      def ancestor_tree_keys
        self.class.ancestor_tree_keys(self.tree_info.nv,self.tree_info.dv)
      end

      def query_ancestor_tree_keys
        check_parent = tree_search_class.where(:_id => self[tree_parent_id_field]).first
        return nil if (check_parent.nil? || check_parent == [])
        rethash = {:nv => check_parent.tree_info.nv, 
                   :dv => check_parent.tree_info.dv, 
                   :snv => check_parent.tree_info.snv, 
                   :sdv => check_parent.tree_info.sdv}
      end

      def tree_keys
        { :nv => self.tree_info.nv, 
          :dv => self.tree_info.dv, 
          :snv => self.tree_info.snv, 
          :sdv => self.tree_info.sdv}
      end

      # verifies parent keys from calculation and query
      # this might not work for nested saves...
      def correct_parent?(nv, dv)
        # get nv/dv from parent
        check_ancestor_keys = query_ancestor_tree_keys()
        return false if (check_ancestor_keys == nil)
        calc_ancestor_keys = self.class.ancestor_tree_keys(nv, dv)
        if ( (calc_ancestor_keys[:nv] == check_ancestor_keys[:nv]) \
          && (calc_ancestor_keys[:dv] == check_ancestor_keys[:dv]) \
          && (calc_ancestor_keys[:snv] == check_ancestor_keys[:snv]) \
          && (calc_ancestor_keys[:sdv] == check_ancestor_keys[:sdv]) \
          )
          return true
        end
      end

      def disable_timestamp_callback
        self.class.skip_callback(:save, :before, :update_timestamps ) if self.respond_to?("updated_at")
      end

      def enable_timestamp_callback
        self.class.set_callback(:save, :before, :update_timestamps ) if self.respond_to?("updated_at")
      end

      def root?
        self[tree_parent_id_field].nil?
      end

      def root
        self.tree_info.path.first.nil? ? self : tree_search_class.find(self.tree_info.path.first)
      end

      def ancestors
        return [] if root?
        tree_search_class.find(self.tree_info.path)
      end

      def self_and_ancestors
        ancestors << self
      end

      def has_siblings?
        tree_search_class.where(:_id => { "$ne" => self._id })
                         .where(tree_parent_id_field => self[tree_parent_id_field])
                         .sort(self.class.tree_sort_order()).count
      end

      def siblings
        tree_search_class.where({
          :_id => { "$ne" => self._id },
          tree_parent_id_field => self[tree_parent_id_field]
        }).sort(self.class.tree_sort_order()).all
      end

      def self_and_siblings
        tree_search_class.where({
          tree_parent_id_field => self[tree_parent_id_field]
        }).sort(self.class.tree_sort_order()).all
      end

      def children?
        return false if ((self.children == nil) || (self.children == []))
        return true
      end

      def children
        tree_search_class.where(tree_parent_id_field => self._id).sort(self.class.tree_sort_order()).all
      end

      def descendants
        return [] if new_record?
        tree_search_class.where("tree_info.path" => self._id).sort(self.class.tree_sort_order()).all
      end

      def self_and_descendants
        [self] + self.descendants
      end

      def is_ancestor_of?(other)
        other.tree_info.path.include?(self._id)
      end

      def is_or_is_ancestor_of?(other)
        (other == self) or is_ancestor_of?(other)
      end

      def is_descendant_of?(other)
        self.tree_info.path.include?(other._id)
      end

      def is_or_is_descendant_of?(other)
        (other == self) or is_descendant_of?(other)
      end

      def is_sibling_of?(other)
        (other != self) and (other[tree_parent_id_field] == self[tree_parent_id_field])
      end

      def is_or_is_sibling_of?(other)
        (other == self) or is_sibling_of?(other)
      end

      def move_children
        if @_will_move
          @_will_move = false
          # disable_tree_callbacks()
          # disable update_tree_info_callback
          _position = 0
          self.disable_timestamp_callback()
          self.children.each do |child|
            child.update_path!
            child.update_nv_dv!(:position => _position)
            puts "Update Child - #{child.name.inspect} #{child.changes.inspect}"
            puts "#{child.updated_at.to_f}"
            child.save
            child.reload
            puts "#{child.updated_at.to_f}"
            child.save
            child.reload
            puts "#{child.updated_at.to_f}"
            child.reload
            puts "#{child.updated_at.to_f}"

            _position += 1
          end
          self.enable_timestamp_callback()

          # enable_tree_callbacks()
          @_will_move = true
        end
      end

      def destroy_descendants
        tree_search_class.destroy(self.descendants.map(&:_id))
      end

    end # Module Tree
  end # Module Plugins
end # Module MongoMapper
