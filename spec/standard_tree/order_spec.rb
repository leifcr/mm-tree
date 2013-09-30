require 'spec_helper'

describe "Ordered Tree" do
  before(:each) do
    @node_1       = OrderedCategory.create(:name => "Node 1", :value => 2)
    @node_1_1     = OrderedCategory.create(:name => "Node 1", :parent => @node_1, :value => 1)
    @node_1_2     = OrderedCategory.create(:name => "Node 1.2", :parent => @node_1, :value => 9)
    @node_1_2_1   = OrderedCategory.create(:name => "Node 1.2.1", :parent => @node_1_2, :value => 2)
    @node_1_3     = OrderedCategory.create(:name => "Node 1.3", :parent => @node_1, :value => 5)
    @node_2       = OrderedCategory.create(:name => "Node 2", :value => 1)
  end
  it "should have root nodes order" do
    OrderedCategory.roots.should be_in_order [@node_2, @node_1]
  end

  it "children of Node 1 should be in order" do
    @node_1.children.should be_in_order [@node_1_1, @node_1_3, @node_1_2]
  end

  # it "should Node 1 descendants should be in order" do
  #   @node_1.descendants.should == [@node_1_1, @node_1_3, @node_1_2, @node_1_2_1]
  # end

  # it "should Node 1 self and descendants should be in order" do
  #   @node_1.self_and_descendants.should == [@node_1, @node_1_1, @node_1_3, @node_1_2, @node_1_2_1]
  # end

  # it "should Node 1.2 siblings should be in order" do
  #   @node_1_2.siblings.should == [@node_1_1, @node_1_3]
  # end

  # it "should Node 1.2 self and siblings should be in order" do
  #   @node_1_2.self_and_siblings.should == [@node_1_1, @node_1_3, @node_1_2]
  # end

  # it "should Node 1 self and siblings should be in order" do
  #   @node_1.self_and_siblings.should == [@node_2, @node_1]
  # end
end