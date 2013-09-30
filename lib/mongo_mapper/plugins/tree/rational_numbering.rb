require 'rational_number'

module MongoMapper
  module Plugins
    module Tree
      module RationalNumbering
        extend ActiveSupport::Concern

        module ClassMethods

          ##
          # Force all rational number keys to update
          # NOTE: This can take time if your collection is large, and is recommended to do as a background job
          #
          # @return [undefined]
          #
          def rekey_all!
            # rekey keys for each root. will do children
            _pos = 1
            root_rational = RationalNumber.new
            self.roots.each do |root|
              new_rational = root_rational.child_from_position(_pos)
              if new_rational != self.to_rational_number
                root.move_rational_number(new_rational.nv, new_rational.dv, {:ignore_conflict => true})
                root.save!
                # root.reload # Should caller be responsible for reloading?
              end
              root.rekey_children
              _pos += 1
            end
          end

          # Temporary disable tree_sort order

          # def tree_sort_order
          #   if !tree_use_rational_numbers
          #     "#{tree_order} #{tree_info_depth_field}"
          #   else
          #     tree_nv_div_dv_field.asc
          #   end
          # end

        end # Module ClassMethods

        ##
        # Initialize the rational tree document
        #
        # @return [undefined]
        #
        def initialize(*args)
          rational_number({:force => true})
          @_set_rational_number = false
          super
        end


        included do

          class_attribute :tree_nv_field
          class_attribute :tree_dv_field
          class_attribute :tree_snv_field
          class_attribute :tree_sdv_field
          class_attribute :tree_nv_div_dv_field

          self.tree_nv_field  ||= :tree_nv
          self.tree_dv_field  ||= :tree_dv
          self.tree_snv_field ||= :tree_snv
          self.tree_sdv_field ||= :tree_sdv
          self.tree_nv_div_dv_field ||= :tree_nv_div_dv

          class_attribute :tree_order

          key tree_nv_field,  Integer, :default => 0
          key tree_dv_field,  Integer, :default => 1
          key tree_snv_field, Integer, :default => 1
          key tree_sdv_field, Integer, :default => 0

          key tree_nv_div_dv_field, Float, :default => 0

          # An index for all the keys above are recomended for performance.

  # FIX VALIDATIONS... this is messy!
          validate          :validate_rational_hierarchy

          before_validation :set_rational_values_if_missing

          after_update_path :update_rational_number
          after_save        :move_children
          before_destroy    :destroy_descendants
        end

        ##
        #
        # Validate that this document has the correct parent document through a query!
        #
        # @return true for valid, else false
        #
        def validate_rational_hierarchy
          if (self.changes.include?(tree_nv_field) && self.changes.include?(tree_dv_field) && self.changes.include?(tree_parent_id_field))
            rational_number({:force => true}) # Update rational number stored at @rational_number.
            if !correct_rational_parent?(@rational_number.nv, @rational_number.nv)
              errors.add(:base, I18n.t(:cyclic, :scope => [:mongo_mapper, :errors, :messages, :tree]))
            end
          end
        end

        ##
        #
        # Update the rational numbers on the document if any moves has been performed
        #
        # @param  [Hash] Options
        #
        # Options can be:
        #
        # :force => force an update on the rational number
        # :position => force position for the rational number
        #
        # Should calculate next free nv/dv and set that if parent has changed.
        # (set values to "missing and call missing function should work")
        #
        # @return [undefined]
        #
        def update_rational_number(opts = {})
          return if !tree_use_rational_numbers
          if @_set_rational_number == true
            @_set_rational_number = false
            return
          end
          # if changes include tree_nv_field and tree_dv_field, move to new location
          if (self.changes.include?(tree_nv_field) && self.changes.include?(tree_dv_field))
            self.move_rational_number(self[tree_nv_field], self[tree_dv_field])
          # else if changes include parent_id
          elsif (self.changes.include?(tree_parent_id_field)) || opts[:force]
            # only changed parent, needs to find next free position
            # Get rational number from new parent
            a = tree_search_class.find(self[tree_parent_id_field])
            if a.nil?
              raise InvalidParentError, "The parent is nil. This should not happen, unless there is corrupt data in the db."
              return
            end
            if opts[:position]
              new_key = a.to_rational_number.child_from_position(opts[:position])
            else
              new_key = a.to_rational_number.child_from_position(self.has_siblings? + 1)
            end
            self.move_rational_number(new_key.nv, new_key.dv)
          end
        end

        ##
        #
        # Force update of the rational number on the document
        #
        # @param  [Hash] Options
        #
        # Options can be:
        #
        # :force => force an update on the rational number
        # :position => force position for the rational number
        #
        # @return [undefined]
        #
        def update_rational_number!(opts = {})
          update_rational_number({:force => true}.merge(opts))
        end

        ##
        #
        # sets initial nv, dv, snv and sdv values for a new document if not present
        #
        # @return [undefined]
        #
        def set_rational_values_if_missing
          return if !tree_use_rational_numbers
          # Since root rational numbers should never be stored in the DB,
          # as there can be only one.
          # This assumption should be fine
          if @rational_number.root?
            last_sibling = self.siblings.last
            if (last_sibling == nil)
              new_rational_number = self.parent.rational_number.child_from_position(1)
            else
              new_rational_number = self.parent.rational_number.child_from_position(last_sibling.rational_number.position + 1)
            end
            from_rational_number(new_rational_number)
            @_set_rational_number = true
          end
        end


        ##
        #
        # Move the document to a given rational_number position
        #
        # if a document exists on the new position, all siblings are shifted right before moving this document
        # can move without updating conflicting siblings by using :ignore_conflicts in options
        #
        # @param [Integer] The nominator value
        # @param [Integer] The denominator value
        # @param [Hash] Options: :ignore_conflicts (defaults to false)
        #
        # @return [undefined]
        #
        def move_rational_number(nv, dv, opts = {})
          return if !tree_use_rational_numbers

          # don't check for conflict if forced move
          if (!opts[:ignore_conflict])
            conflicting_sibling = tree_search_class.where(tree_nv_field => nv).where(tree_dv_field => dv).first
            if (conflicting_sibling != nil)
              self.disable_timestamp_callback()
              # find nv/dv to the right of conflict and move
              next_key = conflicting_sibling.to_rational_number.next_sibling
              conflicting_sibling.move_rational_number(next_key.nv, next_key.dv)
              conflicting_sibling.save
              self.enable_timestamp_callback()
            end
          end

          # shouldn't be any conflicting sibling now...
          self.from_rational_number(RationalNumber.new(nv,dv))

          # as this is triggered from after_validation, save must be triggered by the caller.
        end

        ##
        #
        # Set the position of this document.
        # (alias for move_rational_number)
        #
        alias :set_position, :move_rational_number


        ##
        #
        # Query the ancestor rational number
        #
        # @return [RationalNumber] returns the rational number for the ancestor or nil for "not found"
        #
        def query_ancestor_rational_number
          check_parent = tree_search_class.where(:_id => self[tree_parent_id_field]).first
          return nil if (check_parent.nil? || check_parent == [])
          check_parent.to_rational_number
        end

        ##
        #
        # Verifies parent keys from calculation and query
        #
        # @return [Boolean] true for correct, else false
        #
        def correct_parent?(nv, dv)
          q_rational_number = query_ancestor_rational_number()
          return false if (q_rational_number == nil)
          return true  if self.to_rational_number.parent == q_rational_number
          false
        end

        ##
        #
        # Rekey each of the children (usually forcefully if a tree has gone "crazy")
        #
        # @return [undefined]
        #
        def rekey_children
          return if (!self.children?)
          _pos = 1
          parent_rational = self.parent.to_rational_number
          self.children.each do |child|
            new_rational = parent_rational.child_from_position(_pos)
            if new_rational != child.to_rational_number
              # forcefully move to new position
              child.move_rational_number(new_rational.nv, new_rational.dv, {:ignore_conflict => true})
              child.save!
              # child.reload # Should caller be responsible for reloading?
            end
            child.rekey_children
            _pos += 1
          end
        end



        ##
        #
        # Not needed, as each child gets the rational number updated after updating path?
        # @return [undefined]
        #
        # def children_update_rational_number
        #   if rearrange_children?
        #     _position = 0
        #     # self.disable_timestamp_callback()
        #     self.children.each do |child|
        #       child.update_rational_number!(:position => _position)
        #       _position += 1
        #     end
        #     # self.enable_timestamp_callback()
        #   end
        # end

      private

        ##
        # Convert to rational number
        #
        # @return [RationalNumber] The rational number for this node
        #
        def rational_number(opts = {})
          if !!opts[:force] or @rational_number == nil
            @rational_number = RationalNumber.new(self[tree_nv_field], self[tree_dv_field], self[tree_snv_field], self[tree_sdv_field])
          end
          @rational_number
        end

        ##
        # Convert from rational number and set keys accordingly
        #
        # @param  [RationalNumber] The rational number for this node
        # @return [undefined]
        #
        def from_rational_number(rational_number)
          self[tree_nv_field]  = rational_number.nv
          self[tree_dv_field]  = rational_number.dv
          self[tree_snv_field] = rational_number.snv
          self[tree_sdv_field] = rational_number.sdv
          self[tree_nv_div_dv_field] = rational_number.number
        end
      end # RationalNumbering
    end # Tree
  end # Plugins
end # MongoMapper

##
# The rational number is root and therefore has no siblings
#
class InvalidParentError < StandardError
end
