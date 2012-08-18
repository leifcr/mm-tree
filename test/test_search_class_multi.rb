require 'helper'

class TestSearchScope < Test::Unit::TestCase
  context "Mixed type tree with unique search classes" do
    setup do
      @shape_1 = Shape.create(:name => "Shape 1")
      @shape_1_1 = Shape.create(:name => "Shape 1.1", :parent => @shape_1)
      @shape_1_2 = Shape.create(:name => "Shape 1.2", :parent => @shape_1)
      @triangle_1 = Triangle.create(:name => "Triangle 1")
      @triangle_1_1 = Triangle.create(:name => "Triangle 1.1", :parent => @triangle_1)
      @triangle_1_2 = Triangle.create(:name => "Triangle 1.2", :parent => @triangle_1)
      @cube_1 = Cube.create(:name => "Cube 1")
      @cube_1_1 = Cube.create(:name => "Cube 1.1", :parent => @cube_1)
      @cube_1_2 = Cube.create(:name => "Cube 1.2", :parent => @cube_1)
      @cube_1_2_1 = Cube.create(:name => "Cube 1.2.1", :parent => @cube_1_2)
      @cube_1_2_2 = Cube.create(:name => "Cube 1.2.2", :parent => @cube_1_2)
      @cube_1_2_2_1 = Cube.create(:name => "Cube 1.2.2.1", :parent => @cube_1_2_1)
    end

    should "return cubes as children of cube_1" do
      @cube_1.children.should eql?([@cube_1_1, @cube_1_2, @cube_1_2_1, @cube_1_2_2, @cube_1_2_2_1])
    end

    should "return two shapes as children of shape_1" do
      @cube_1.children.count.should eql?(2)
    end

    should "return triangles as children of triangles" do
      @triangle_1.children.should eql?([@triangle_1_1, @triangle_1_2])
    end

    should "move a cube child within cubes" do
      @cube_1_2_2.parent = @cube_1
      @cube_1_1.siblings.should eql?([@cube_1_2, @cube_1_2_2])
      @cube_1.descendants.should eql?([@cube_1_1, @cube_1_2, @cube_1_2_2, @cube_1_2_2_1, @cube_1_2_1])
    end

    should "return circle and square as children of shape" do
      assert_equal [@circle, @square], @shape.children
    end

    should "return cube_1 as parent of cube_1_1" do
      @cube_1_1.parent.should eql?(@cube_1)
    end

    should "return shape_1 as parent of shape_1_2" do
      @shape_1_2.parent.should eql?(@shape_1)
    end

    should "not allow to set a cube_1 as child of triangle_1" do
      # TODO: add validation that search class of parent and child is same
    end

    should "destroy descendants of shape_1" do
      @shape_1.destroy_descendants
      Shape.find(@shape_1_2._id).should eql?(nil)
      Shape.find(@shape_1_1._id).should eql?(nil)
    end
  end # context "Mixed type tree with unique search classes" do

end # TestSearchScope