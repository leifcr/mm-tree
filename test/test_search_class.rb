require 'helper'

class TestSearchScope < Test::Unit::TestCase
  context "Simple, mixed type tree" do
    setup do
      shape = Shape.create(:name => "Root")
      Circle.create(:name => "Circle", :parent => shape)
      Square.create(:name => "Square", :parent => shape)
    end

    setup do
      # We are loading from the database here because this process proves the point. If we never did it this
      # way, there would be no reason to change the code.
      @shape, @circle, @square = Shape.first, Circle.first, Square.first
    end

    should "return circle and square as children of shape" do
      [@circle, @square].should == @shape.children
    end

    should("return shape as parent of circle") do
      @shape.should == @circle.parent
    end
    should("return shape as parent of square") do
      @shape.should == @square.parent
    end

    should("return square as exclusive sibling of circle") do
      [@square].should ==@circle.siblings
    end

    should "return self and square as inclusive siblings of circle" do
      [@circle, @square].should == @circle.self_and_siblings
    end

    should("return circle as exclusive sibling of square") do 
      [@circle].should == @square.siblings
    end
    should "return self and circle as inclusive siblings of square" do
      [@circle, @square].should == @square.self_and_siblings
    end

    should "return circle and square as exclusive descendants of shape" do
      [@circle, @square].should == @shape.descendants
    end
    should "return shape, circle and square as inclusive descendants of shape" do
      [@shape, @circle, @square].should == @shape.self_and_descendants
    end

    should("return shape as exclusive ancestor of circle") do
      [@shape].should == @circle.ancestors
    end

    should "return self and shape as inclusive ancestors of circle" do
      [@shape, @circle].should == @circle.self_and_ancestors
    end

    should("return shape as exclusive ancestor of square") do
      [@shape].should == @square.ancestors
    end
    should "return self and shape as inclusive ancestors of square" do
      [@shape, @square].should == @square.self_and_ancestors
    end

    should("return shape as root of circle") do
      @shape.should == @square.root 
    end
    should("return shape as root of square") do
      @shape.should == @circle.root 
    end
  end

  context "A tree with mixed types on either side of a branch" do
    setup do
      shape = Shape.create(:name => "Root")
      circle = Circle.create(:name => "Circle", :parent => shape)
      Square.create(:name => "Square", :parent => circle)
    end

    setup do
      @shape, @circle, @square = Shape.first, Circle.first, Square.first
    end

    should("return circle as child of shape")   do
      [@circle].should == @shape.children
    end
    should("return square as child of circle")  do
      [@square].should == @circle.children
    end
    should("return circle as parent of square") do
      @circle.should == @square.parent
    end
    should("return shape as parent of circle")  do
      @shape.should == @circle.parent
    end

    should "return circle and square as descendants of shape" do
      [@circle, @square].should == @shape.descendants
    end

    should("return square as descendant of circle") do 
      [@square].should == @circle.descendants
    end

    should "return shape and circle as ancestors of square" do
      [@shape, @circle].should == @square.ancestors
    end

    should("return shape as ancestor of circle") do
      [@shape].should == @circle.ancestors
    end

    should "destroy descendants of shape" do
      @shape.destroy_descendants
      assert_nil Shape.find(@circle._id)
      assert_nil Shape.find(@square._id)
    end
  end

end # TestSearchScope