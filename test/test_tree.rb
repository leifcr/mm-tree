require 'helper'
class TestMongomapperActsAsTree < Test::Unit::TestCase
  context "Tree" do
    setup do
      @node_1     = Category.create(:name => "Node 1")
      @node_1_1    = Category.create(:name => "Node 1.1", :parent => @node_1)
      @node_1_2    = Category.create(:name => "Node 1.2", :parent => @node_1)
      @node_1_2_1  = Category.create(:name => "Node 1.2.1", :parent => @node_1_2)
      @node_1_2_2  = Category.create(:name => "Node 1.2.2", :parent => @node_1_2)
      @node_1_3    = Category.create(:name => "Node 1.3", :parent => @node_1)
      #@node_4    = Category.create(:name => "Node 3", :parent => @node_1)
      @node_2     = Category.create(:name => "Node 2")
      @node_2_1    = Category.create(:name => "Node 2.1", :parent => @node_2)
      @node_2_2    = Category.create(:name => "Node 2.2", :parent => @node_2)
      @node_2_3    = Category.create(:name => "Node 2.3", :parent => @node_2)
      @node_2_4    = Category.create(:name => "Node 2.4", :parent => @node_2)
      @node_2_4_1  = Category.create(:name => "Node 2.4.1", :parent => @node_2_4)
      @node_2_4_2  = Category.create(:name => "Node 2.4.2", :parent => @node_2_4)
      @node_2_4_3  = Category.create(:name => "Node 2.4.3", :parent => @node_2_4)
      @node_2_4_1_1  = Category.create(:name => "Node 2.4.1.1", :parent => @node_2_4_1)
    end #setup do

    should "create node from id " do
      assert Category.create(:name => "Node 1.4", :parent_id => @node_1.id).parent == @node_1
    end

    should "have roots" do
      Category.roots.should == [@node_1, @node_2]
    end

    context "node" do
      should "have a root" do
        @node_1.root.should == @node_1
        @node_1.root.should_not == @node_2.root
        @node_1.should == @node_1_2_1.root
      end

      should "have ancestors" do
        @node_1.ancestors.should == []
        @node_1_2_1.ancestors.should == [@node_1, @node_1_2]
        @node_1.self_and_ancestors.should == [@node_1]
        @node_1_2_1.self_and_ancestors.should == [@node_1, @node_1_2, @node_1_2_1]
      end

      should "have siblings" do
        @node_1.siblings.should == [@node_2]
        @node_1_2.siblings.should == [@node_1_1, @node_1_3]
        @node_1_2_1.siblings.should == [@node_1_2_2]
        @node_1.self_and_siblings.should == [@node_1, @node_2]
        @node_1_2.self_and_siblings.should == [@node_1_1, @node_1_2, @node_1_3]
        @node_1_2_1.self_and_siblings.should == [@node_1_2_1, @node_1_2_2]
        @node_1_2_2.self_and_siblings.should == [@node_1_2_1, @node_1_2_2]
      end

      should "set depth" do
        @node_1.tree_info.depth.should == 0
        @node_1_1.tree_info.depth.should == 1
        @node_1_2_1.tree_info.depth.should == 2
      end

      should "have children" do
        assert @node_1_2_1.children.empty?
        @node_1.children.should == [@node_1_1, @node_1_2, @node_1_3]
      end

      should "have descendants" do
        @node_1.descendants.should == [@node_1_1, @node_1_2, @node_1_2_1, @node_1_2_2, @node_1_3]
        @node_1_2.descendants.should == [@node_1_2_1, @node_1_2_2]
        assert @node_1_2_1.descendants.empty?
        @node_1.self_and_descendants.should == [@node_1, @node_1_1, @node_1_2, @node_1_2_1, @node_1_2_2, @node_1_3]
        @node_1_2.self_and_descendants.should == [@node_1_2, @node_1_2_1, @node_1_2_2]
        @node_1_2_1.self_and_descendants.should == [@node_1_2_1]
      end

      should "be able to tell if ancestor" do
        assert @node_1.is_ancestor_of?(@node_1_1)
        assert ! @node_2.is_ancestor_of?(@node_1_2_1)
        assert ! @node_1_2.is_ancestor_of?(@node_1_2)

        assert @node_1.is_or_is_ancestor_of?(@node_1_1)
        assert ! @node_2.is_or_is_ancestor_of?(@node_1_2_1)
        assert @node_1_2.is_or_is_ancestor_of?(@node_1_2)
      end

      should "be able to tell if descendant" do
        assert ! @node_1.is_descendant_of?(@node_1_1)
        assert @node_1_1.is_descendant_of?(@node_1)
        assert ! @node_1_2.is_descendant_of?(@node_1_2)

        assert ! @node_1.is_or_is_descendant_of?(@node_1_1)
        assert @node_1_1.is_or_is_descendant_of?(@node_1)
        assert @node_1_2.is_or_is_descendant_of?(@node_1_2)
      end

      should "be able to tell if sibling" do
        assert ! @node_1.is_sibling_of?(@node_1_1)
        assert ! @node_1_1.is_sibling_of?(@node_1_1)
        assert ! @node_1_2.is_sibling_of?(@node_1_2)

        assert ! @node_1.is_or_is_sibling_of?(@node_1_1)
        assert @node_1_1.is_or_is_sibling_of?(@node_1_2)
        assert @node_1_2.is_or_is_sibling_of?(@node_1_2)
      end

      should "destroy descendants when destroyed" do
        @node_1_2.destroy
        assert_nil Category.find(@node_1_2_1._id)
      end

      context "when moving" do
        should "recalculate path and depth" do
          @node_1_3.parent = @node_1_2
          @node_1_3.save

          assert @node_1_2.is_or_is_ancestor_of?(@node_1_3)
          assert @node_1_3.is_or_is_descendant_of?(@node_1_2)
          assert @node_1_2.children.include?(@node_1_3)
          assert @node_1_2.descendants.include?(@node_1_3)
          assert @node_1_2_1.is_or_is_sibling_of?(@node_1_3)
          assert @node_1_2_2.is_or_is_sibling_of?(@node_1_3)
          @node_1_3.tree_info.depth.should == 2
        end

        should "move children on save" do
          @node_1_2.parent = @node_2

          assert ! @node_2.is_or_is_ancestor_of?(@node_1_2_1)
          assert ! @node_1_2_1.is_or_is_descendant_of?(@node_2)
          assert ! @node_2.descendants.include?(@node_1_2_1)

          @node_1_2.save
          @node_1_2_1.reload

          assert @node_2.is_or_is_ancestor_of?(@node_1_2_1)
          assert @node_1_2_1.is_or_is_descendant_of?(@node_2)
          assert @node_2.descendants.include?(@node_1_2_1)
        end

        should "move children on save and don't touch timestamps for children" do
          @node_2_4.parent = @node_1

          before_created_at_2_4_1   = @node_2_4_1.created_at
          before_updated_at_2_4_1   = @node_2_4_1.updated_at
          before_created_at_2_4_1_1 = @node_2_4_1_1.created_at
          before_updated_at_2_4_1_1 = @node_2_4_1_1.updated_at

          Timecop.freeze(Time.now + 2.seconds) do
            @node_2_4.save
          end
          @node_2_4_1.reload

          # until mongo_mapper implements timefix, do
          @node_2_4_1.created_at.to_f.should be_close(before_created_at_2_4_1.to_f, 0.001)
          @node_2_4_1.updated_at.to_f.should be_close(before_updated_at_2_4_1.to_f, 0.001)
          # @node_2_4_1_1.created_at.to_f.should be_close(before_created_at_2_4_1_1.to_f, 0.001)
          # @node_2_4_1_1.updated_at.to_f.should be_close(before_updated_at_2_4_1_1.to_f, 0.001)

          # when mongo_mapper implements timefix:
          # @node_2_4_1.created_at.should eql?(before_created_at_2_4_1)
          # @node_2_4_1.updated_at.should eql?(before_updated_at_2_4_1)
          # @node_2_4_1_1.created_at.should be_close(before_created_at_2_4_1_1)
          # @node_2_4_1_1.updated_at.should be_close(before_updated_at_2_4_1_1)

        end

        should "check against cyclic graph" do
          @node_1.parent = @node_1_2_1
          @node_1.save
          @node_1.valid?.should == false
          I18n.t(:'mongo_mapper.errors.messages.tree.cyclic').should == @node_1.errors[:base].first
        end

        should "be able to become root" do
          @node_1_2.parent = nil
          @node_1_2.save
          @node_1_2.reload
          assert_nil @node_1_2.parent
          @node_1_2_1.reload
          assert (@node_1_2_1.tree_info.path == [@node_1_2.id])
        end
      end # context "when moving" do
    end # context "node" do

    context "root node" do
      should "not have a parent" do
        assert_nil @node_1.parent
      end
    end

    context "node_node" do
      should "have a parent" do
        assert_equal @node_1_2, @node_1_2_1.parent
      end
    end

    context "node (keys)" do
      should "find keys from id" do
        assert Category.find(@node_1._id).tree_keys == @node_1.tree_keys, "Query doesn't match created object #{@node_1.name}"
        assert Category.find(@node_2_4_1_1._id).tree_keys == @node_2_4_1_1.tree_keys, "Query doesn't match created object #{@node_2_4_1_1.name}"
      end

      should "have correct keys" do
        @node_1.tree_keys.should        == Hash[:nv => 1, :dv => 1, :snv => 2, :sdv => 1]
        @node_2.tree_keys.should        == Hash[:nv => 2, :dv => 1, :snv => 3, :sdv => 1]
        @node_2_1.tree_keys.should      == Hash[:nv => 5, :dv => 2, :snv => 8, :sdv => 3]
        @node_1_3.tree_keys.should      == Hash[:nv => 7, :dv => 4, :snv => 9, :sdv => 5]
        @node_2_4.tree_keys.should      == Hash[:nv => 14, :dv => 5, :snv => 17, :sdv => 6]
        @node_2_4_1.tree_keys.should    == Hash[:nv => 31, :dv => 11, :snv => 48, :sdv => 17]
        @node_2_4_3.tree_keys.should    == Hash[:nv => 65, :dv => 23, :snv => 82, :sdv => 29]
        @node_2_4_1_1.tree_keys.should  == Hash[:nv => 79, :dv => 28, :snv => 127, :sdv => 45]
      end

      should "find and calculate ancestor keys from given keys" do
        assert Category.ancestor_tree_keys(@node_1.tree_info.nv, @node_1.tree_info.dv) == Hash[:nv => 0, :dv => 1, :snv => 1, :sdv => 0], "Ancestor keys for #{@node_1.name} is wrong"
        assert Category.ancestor_tree_keys(@node_2_1.tree_info.nv, @node_2_1.tree_info.dv) == @node_2.tree_keys(), "Ancestor keys for #{@node_2_1.name} is not matching keys for #{@node_2.name}"
        assert Category.ancestor_tree_keys(@node_2_2.tree_info.nv, @node_2_2.tree_info.dv) == @node_2.tree_keys(), "Ancestor keys for #{@node_2_2.name} is not matching keys for #{@node_2.name}"
        assert Category.ancestor_tree_keys(@node_2_4_1.tree_info.nv, @node_2_4_1.tree_info.dv) == @node_2_4.tree_keys(), "Ancestor keys for #{@node_2_4_1.name} is not matching keys for #{@node_2_4.name}"
        assert Category.ancestor_tree_keys(@node_2_4_1_1.tree_info.nv, @node_2_4_1_1.tree_info.dv) == @node_2_4_1.tree_keys(), "Ancestor keys for #{@node_2_4_1_1.name} is not matching keys for #{@node_2_4_1.name}"
      end

      should "find positions from given keys" do
        assert Category.position_from_nv_dv(@node_1.tree_info.nv, @node_1.tree_info.dv) == 1,             "Wrong position for #{@node_1.name}, got #{Category.position_from_nv_dv(@node_1.tree_info.nv, @node_1.tree_info.dv)}, expected: 1"
        assert Category.position_from_nv_dv(@node_2_1.tree_info.nv, @node_2_1.tree_info.dv) == 1,         "Wrong position for #{@node_2_1.name}, got #{Category.position_from_nv_dv(@node_2_1.tree_info.nv, @node_2_1.tree_info.dv)}, expected: 1"
        assert Category.position_from_nv_dv(@node_2_2.tree_info.nv, @node_2_2.tree_info.dv) == 2,         "Wrong position for #{@node_2_2.name}, got #{Category.position_from_nv_dv(@node_2_2.tree_info.nv, @node_2_2.tree_info.dv)}, expected: 2"
        assert Category.position_from_nv_dv(@node_2_3.tree_info.nv, @node_2_3.tree_info.dv) == 3,         "Wrong position for #{@node_2_3.name}, got #{Category.position_from_nv_dv(@node_2_3.tree_info.nv, @node_2_3.tree_info.dv)}, expected: 3"
        assert Category.position_from_nv_dv(@node_2_4.tree_info.nv, @node_2_4.tree_info.dv) == 4,         "Wrong position for #{@node_2_4.name}, got #{Category.position_from_nv_dv(@node_2_4.tree_info.nv, @node_2_4.tree_info.dv)}, expected: 4"
        assert Category.position_from_nv_dv(@node_2_4_1.tree_info.nv, @node_2_4_1.tree_info.dv) == 1,     "Wrong position for #{@node_2_4_1.name}, got #{Category.position_from_nv_dv(@node_2_4_1.tree_info.nv, @node_2_4_1.tree_info.dv)}, expected: 1"
        assert Category.position_from_nv_dv(@node_2_4_1_1.tree_info.nv, @node_2_4_1_1.tree_info.dv) == 1, "Wrong position for #{@node_2_4_1_1.name}, got #{Category.position_from_nv_dv(@node_2_4_1_1.tree_info.nv, @node_2_4_1_1.tree_info.dv)}, expected: 1"
      end

      should "verify ancestor keys" do
        assert @node_1_2.ancestor_tree_keys()     == @node_1.tree_keys(),     "#{@node_1_2.name} ancestor keys doesn't match #{@node_1.name} tree keys"
        assert @node_1_2_1.ancestor_tree_keys()   == @node_1_2.tree_keys(),   "#{@node_1_2_1.name} ancestor keys doesn't match #{@node_1_2.name} tree keys"
        assert @node_2_4_1_1.ancestor_tree_keys() == @node_2_4_1.tree_keys(), "#{@node_2_4_1_1.name} ancestor keys doesn't match #{@node_2_4_1.name} tree keys"
      end

      should "move to new specific nv, dv location and move conflicting items" do
        assert @node_2_4.ancestor_tree_keys() == @node_2.tree_keys(), "Before move: #{@node_2_4.name} ancestor keys should match #{@node_2.name} got: #{@node_2_4.ancestor_tree_keys()} expected: #{@node_2.tree_keys()}"
        assert @node_2_4_1.tree_info.depth == 2, "Before move: Depth of #{@node_2_4_1.name} should be 2"
        old_1_2_keys = @node_1_2.tree_keys()
        new_node_1_2_keys = @node_1_2.next_sibling_keys
        @node_2_4.set_position(@node_1_2.tree_info.nv, @node_1_2.tree_info.dv)
        @node_2_4.save
        @node_1_2.reload
        @node_2_4.reload
        @node_2_4_1.reload

        assert @node_1_2.tree_keys() != old_1_2_keys, "After move: #{@node_1_2.name} should have moved to new position, got #{@node_1_2.tree_keys} expected: #{new_node_1_2_keys}"
        assert @node_1_2.tree_keys() == new_node_1_2_keys, "After move: #{@node_1_2.name} should have moved to new position, got #{@node_1_2.tree_keys} expected: #{new_node_1_2_keys}"
        assert @node_2_4.tree_keys() == old_1_2_keys, "After move: #{@node_2_4.name} should have taken #{@node_1_2.name}'s position, got: #{@node_2_4.tree_keys}, expected: #{old_1_2_keys}"
        assert @node_2_4_1.ancestor_tree_keys()   == @node_2_4.tree_keys(),   "After move: #{@node_2_4_1.name} ancestor keys should match #{@node_2_4.name} got: #{@node_2_4_1.ancestor_tree_keys()} expected: #{@node_2_4.tree_keys()}"
      end

      should "move @node_2_4 to root position" do
        assert @node_2_4.ancestor_tree_keys() == @node_2.tree_keys(), "Before move: #{@node_2_4.name} ancestor keys should match #{@node_2.name} got: #{@node_2_4.ancestor_tree_keys()} expected: #{@node_2.tree_keys()}"
        assert @node_2_4_1.tree_info.depth == 2, "Before move: Depth of #{@node_2_4_1.name} should be 2"
        @node_2_4.parent = nil
        @node_2_4.save
        @node_2_4.reload
        assert @node_2_4.root?, "#{@node_2_4.name} is not root"
        assert @node_2_4.tree_keys()          == @node_2.next_sibling_keys(),     "After move: #{@node_2_4.name} keys should match keys #{@node_2.name} sibling keys. got: #{@node_2_4.tree_keys()} expected: #{@node_2.next_sibling_keys()}" 
        assert @node_2_4.ancestor_tree_keys() == Hash[:nv => 0, :dv => 1, :snv => 1, :sdv => 0],     "After move: #{@node_2_4.name} ancestor keys should match root keys. got: #{@node_2_4.ancestor_tree_keys()} expected: #{Hash[:nv => 0, :dv => 1, :snv => 1, :sdv => 0]}"
      # TODO: OVERRIDE RELOAD TO LOAD ALL CHILDREN IN MEMORY/CACHE/ASSOCS
        @node_2_4_1.reload
        assert @node_2_4_1.tree_info.path.count == 1, "After move:  Path length of #{@node_2_4_1.name} should only be 1"
        assert @node_2_4_1.tree_info.depth == 1, "After move: Depth of #{@node_2_4_1.name} should be 1"
        assert @node_2_4_1.ancestor_tree_keys()   == @node_2_4.tree_keys(),   "After move: #{@node_2_4_1.name} ancestor keys should match #{@node_2_4.name} got: #{@node_2_4_1.ancestor_tree_keys()} expected: #{@node_2_4.tree_keys()}"
      # TODO: OVERRIDE RELOAD TO LOAD ALL CHILDREN IN MEMORY/CACHE/ASSOCS
        @node_2_4_1_1.reload
        assert @node_2_4_1_1.ancestor_tree_keys() == @node_2_4_1.tree_keys(), "After move: #{@node_2_4_1_1.name} ancestor keys should match #{@node_2_4_1.name} got: #{@node_2_4_1_1.ancestor_tree_keys()} expected: #{@node_2_4_1.tree_keys()}"
      end
      
      should "should have changed nv/dv after changing parent (id)" do
        old_keys = @node_1_2.tree_keys()
        @node_1_2.parent = @node_2
        # before saved
        assert @node_1_2.ancestor_tree_keys() == @node_1.tree_keys(), "Before move: #{@node_1_2.name} ancestor keys should match #{@node_1.name} got: #{@node_1_2.ancestor_tree_keys()} expected: #{@node_1.tree_keys()}"
        assert @node_1_2_1.ancestor_tree_keys() == @node_1_2.tree_keys(), "Before move #{@node_1_2_1.name} ancestor keys should match #{@node_1_2.name} got: #{@node_1_2_1.ancestor_tree_keys()} expected: #{@node_1_2.tree_keys()}"

        @node_1_2.save
        @node_1_2.reload
        @node_1_2_1.reload

        assert @node_1_2.tree_keys() != old_keys, "#{@node_1_2} keys should not be same as old"
        assert @node_1_2.ancestor_tree_keys() == @node_2.tree_keys(), "After move: #{@node_1_2.name} ancestor keys should match #{@node_2.name} got: #{@node_1_2.ancestor_tree_keys()} expected: #{@node_2.tree_keys()}"
        # should still be able to find correct keys for child of moved item
        assert @node_1_2_1.ancestor_tree_keys() == @node_1_2.tree_keys(), "After move #{@node_1_2_1.name} ancestor keys should match #{@node_1_2.name} got: #{@node_1_2_1.ancestor_tree_keys()} expected: #{@node_1_2.tree_keys()}"
      end
    end # tree keys

    should "rekey the entire treestructre" do
      # TODO
    end

  end #Context "Tree" do
end