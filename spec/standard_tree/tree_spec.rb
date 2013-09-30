require 'spec_helper'

describe "Standard Tree" do
  before(:each) do
    @node_1        = Category.create(:name => "Node 1")
    @node_1_1      = Category.create(:name => "Node 1.1", :parent => @node_1)
    @node_1_2      = Category.create(:name => "Node 1.2", :parent => @node_1)
    @node_1_2_1    = Category.create(:name => "Node 1.2.1", :parent => @node_1_2)
    @node_1_2_2    = Category.create(:name => "Node 1.2.2", :parent => @node_1_2)
    @node_1_3      = Category.create(:name => "Node 1.3", :parent => @node_1)
    @node_2        = Category.create(:name => "Node 2")
    @node_2_1      = Category.create(:name => "Node 2.1", :parent => @node_2)
    @node_2_2      = Category.create(:name => "Node 2.2", :parent => @node_2)
    @node_2_3      = Category.create(:name => "Node 2.3", :parent => @node_2)
    @node_2_4      = Category.create(:name => "Node 2.4", :parent => @node_2)
    @node_2_4_1    = Category.create(:name => "Node 2.4.1", :parent => @node_2_4)
    @node_2_4_2    = Category.create(:name => "Node 2.4.2", :parent => @node_2_4)
    @node_2_4_3    = Category.create(:name => "Node 2.4.3", :parent => @node_2_4)
    @node_2_4_1_1  = Category.create(:name => "Node 2.4.1.1", :parent => @node_2_4_1)
  end

  describe "class functions" do

    it "should have roots" do
      Category.roots.should =~ [@node_1, @node_2]
    end

  end

  describe "node" do


    it "should create node from id " do
      a = Category.create(:name => "Node 1.4", Category.tree_parent_id_field => @node_1.id).parent
      a.should == @node_1
    end

    context "root node" do
      it "should not have a parent" do
        @node_1.parent.should be_nil
      end
    end

    it "should have a root" do
      @node_1.root.should == @node_1
      @node_1.root.should_not == @node_2.root
      @node_1.should == @node_1_2_1.root
    end

    it "child node should have a parent" do
      @node_1_2.should == @node_1_2_1.parent
    end

    it "should have ancestors" do
      @node_1.ancestors.empty?.should be_true
      @node_1_2_1.ancestors.should =~ [@node_1, @node_1_2]
      @node_1.self_and_ancestors.should =~ [@node_1]
      @node_1_2_1.self_and_ancestors.should =~ [@node_1, @node_1_2, @node_1_2_1]
    end

    it "should have siblings" do
      @node_1.siblings.should =~ [@node_2]
      @node_1_2.siblings.should =~ [@node_1_1, @node_1_3]
      @node_1_2_1.siblings.should =~ [@node_1_2_2]
      @node_1.self_and_siblings.should =~ [@node_1, @node_2]
      @node_1_2.self_and_siblings.should =~ [@node_1_1, @node_1_2, @node_1_3]
      @node_1_2_1.self_and_siblings.should =~ [@node_1_2_1, @node_1_2_2]
      @node_1_2_2.self_and_siblings.should =~ [@node_1_2_1, @node_1_2_2]
    end

    it "should have depth set" do
      @node_1[Category.tree_depth_field].should == 0
      @node_1_1[Category.tree_depth_field].should == 1
      @node_1_2_1[Category.tree_depth_field].should == 2
    end

    it "should have children" do
      @node_1_2_1.children.empty?.should be_true
      @node_1.children.should =~ [@node_1_1, @node_1_2, @node_1_3]
    end

    it "should have descendants" do
      @node_1.descendants.should =~ [@node_1_1, @node_1_2, @node_1_2_1, @node_1_2_2, @node_1_3]
      @node_1_2.descendants.should =~ [@node_1_2_1, @node_1_2_2]
      @node_1_2_1.descendants.empty?.should be_true
      @node_1.self_and_descendants.should =~ [@node_1, @node_1_1, @node_1_2, @node_1_2_1, @node_1_2_2, @node_1_3]
      @node_1_2.self_and_descendants.should =~ [@node_1_2, @node_1_2_1, @node_1_2_2]
      @node_1_2_1.self_and_descendants.should =~ [@node_1_2_1]
    end

    it "should be able to tell if ancestor" do

      @node_1.is_ancestor_of?(@node_1_1).should be_true
      @node_2.is_ancestor_of?(@node_1_2_1).should be_false
      @node_1_2.is_ancestor_of?(@node_1_2).should be_false

      @node_1.is_or_is_ancestor_of?(@node_1_1).should be_true
      @node_2.is_or_is_ancestor_of?(@node_1_2_1).should be_false
      @node_1_2.is_or_is_ancestor_of?(@node_1_2).should be_true
    end

    it "should be able to tell if descendant" do
      @node_1.is_descendant_of?(@node_1_1).should be_false
      @node_1_1.is_descendant_of?(@node_1).should be_true
      @node_1_2.is_descendant_of?(@node_1_2).should be_false

      @node_1.is_or_is_descendant_of?(@node_1_1).should be_false
      @node_1_1.is_or_is_descendant_of?(@node_1).should be_true
      @node_1_2.is_or_is_descendant_of?(@node_1_2).should be_true
    end

    it "should be able to tell if sibling" do
      @node_1.is_sibling_of?(@node_1_1).should be_false
      @node_1_1.is_sibling_of?(@node_1_1).should be_false
      @node_1_2.is_sibling_of?(@node_1_2).should be_false

      @node_1.is_or_is_sibling_of?(@node_1_1).should be_false
      @node_1_1.is_or_is_sibling_of?(@node_1_2).should be_true
      @node_1_2.is_or_is_sibling_of?(@node_1_2).should be_true
    end

    it "should destroy descendants when destroyed" do
      @node_1_2.destroy
      Category.find(@node_1_2_1._id).should be_nil
    end

    describe "when moving" do
      it "should recalculate path and depth" do
        @node_1_3.parent = @node_1_2
        @node_1_3.save

        @node_1_2.is_or_is_ancestor_of?(@node_1_3).should be_true
        @node_1_3.is_or_is_descendant_of?(@node_1_2).should be_true
        @node_1_2.children.include?(@node_1_3).should be_true
        @node_1_2.descendants.include?(@node_1_3).should be_true
        @node_1_2_1.is_or_is_sibling_of?(@node_1_3).should be_true
        @node_1_2_2.is_or_is_sibling_of?(@node_1_3).should be_true
        @node_1_3[Category.tree_depth_field].should == 2
      end

      it "should move children on save" do
        @node_1_2.parent = @node_2

        @node_2.is_or_is_ancestor_of?(@node_1_2_1).should be_false
        @node_1_2_1.is_or_is_descendant_of?(@node_2).should be_false
        @node_2.descendants.include?(@node_1_2_1).should be_false

        @node_1_2.save
        @node_1_2_1.reload

        @node_2.is_or_is_ancestor_of?(@node_1_2_1).should be_true
        @node_1_2_1.is_or_is_descendant_of?(@node_2).should be_true
        @node_2.descendants.include?(@node_1_2_1).should be_true
      end

      it "should move children on save and don't touch timestamps for children" do
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
        # BE_CLOSE IS DEPRECATED
        #@node_2_4_1.created_at.to_f.should be_close(before_created_at_2_4_1.to_f, 0.001)
        #@node_2_4_1.updated_at.to_f.should be_close(before_updated_at_2_4_1.to_f, 0.001)

        # @node_2_4_1_1.created_at.to_f.should be_close(before_created_at_2_4_1_1.to_f, 0.001)
        # @node_2_4_1_1.updated_at.to_f.should be_close(before_updated_at_2_4_1_1.to_f, 0.001)

        # when mongo_mapper implements timefix:
        # @node_2_4_1.created_at.should eql?(before_created_at_2_4_1)
        # @node_2_4_1.updated_at.should eql?(before_updated_at_2_4_1)
        # @node_2_4_1_1.created_at.should be_close(before_created_at_2_4_1_1)
        # @node_2_4_1_1.updated_at.should be_close(before_updated_at_2_4_1_1)

      end

      it "should check against cyclic graph" do
        @node_1.parent = @node_1_2_1
        @node_1.save
        @node_1.valid?.should == false
        I18n.t(:'mongo_mapper.errors.messages.tree.cyclic').should == @node_1.errors[:base].first
      end

      it "should verify the path after moving" do
        old_path_1_2   = @node_1_2[Category.tree_path_field].dup
        old_path_1_2_1 = @node_1_2_1[Category.tree_path_field].dup

        @node_1_2.parent = @node_2
        @node_1_2.save
        @node_1_2.reload
        @node_1_2[Category.tree_path_field].should_not == old_path_1_2

        @node_1_2_1.reload
        @node_1_2_1[Category.tree_path_field].should_not == old_path_1_2_1
      end

      it "should be able to become root and move children" do
        @node_1_2.parent = nil
        @node_1_2.save
        @node_1_2.reload
        @node_1_2[Category.tree_path_field].empty?.should be_true
        @node_1_2.parent.should be_nil
        @node_1_2_1.reload
        @node_1_2_1[Category.tree_path_field].should =~ [@node_1_2.id]
      end
    end # describe "when moving" do
  end # describe "node" do
end

