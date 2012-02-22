require 'helper'
class TestMongomapperActsAsTree < Test::Unit::TestCase
  context "Ordered tree" do
    setup do
      @root_1     = OrderedCategory.create(:name => "Root 1", :value => 2)
      @child_1    = OrderedCategory.create(:name => "Child 1", :parent => @root_1, :value => 1)
      @child_2    = OrderedCategory.create(:name => "Child 2", :parent => @root_1, :value => 9)
      @child_2_1  = OrderedCategory.create(:name => "Child 2.1", :parent => @child_2, :value => 2)
      @child_3    = OrderedCategory.create(:name => "Child 3", :parent => @root_1, :value => 5)
      @root_2     = OrderedCategory.create(:name => "Root 2", :value => 1)
    end

    should "return tree as hash in order by value" do
      h = {
        @root_2._id => { 
          :depth => @root_2.depth,
          :path => @root_2.path,
          :name => @root_2.name,
          :value => @root_2.value,
          :children => {}
        },
        @root_1._id => {
          :depth => @root_1.depth,
          :path => @root_1.path,
          :name => @root_1.name,
          :value => @root_1.value,
          :children => {
            @child_1.id => {
              :depth => @child_1.depth,
              :path => @child_1.path,
              :name => @child_1.name,
              :value => @child_1.value,
              :children => {}
            },
            @child_3.id => {
              :depth => @child_3.depth,
              :path => @child_3.path,
              :name => @child_3.name,
              :value => @child_3.value,
              :children => {}
            },
            @child_2.id =>  {
              :depth => @child_2.depth,
              :path => @child_2.path,
              :name => @child_2.name,
              :value => @child_2.value,
              :children =>  {
                @child_2_1.id =>  {
                  :depth => @child_2_1.depth,
                  :path => @child_2_1.path,
                  :name => @child_2_1.name,
                  :value => @child_2_1.value,
                  :children =>  {}
                }
              }
            },
          }
        },
      }
      assert_equal(h, OrderedCategory.tree_as_nested_hash([:name, :value]))
    end

    should "be in order" do
      assert_equal OrderedCategory.roots, [@root_2, @root_1]

      assert_equal @root_1.children, [@child_1, @child_3, @child_2]

      assert_equal @root_1.descendants, [@child_1, @child_3, @child_2, @child_2_1]
      assert_equal @root_1.self_and_descendants, [@root_1, @child_1, @child_3, @child_2, @child_2_1]

      assert_equal @child_2.siblings, [@child_1, @child_3]
      assert_equal @child_2.self_and_siblings, [@child_1, @child_3, @child_2]
      assert_equal @root_1.self_and_siblings, [@root_2, @root_1]
    end
  end
end