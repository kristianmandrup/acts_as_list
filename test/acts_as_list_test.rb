# Load the plugin's test_helper (Rails 2.x needs the path)
require 'test/unit'
begin
  require File.dirname(__FILE__) + '/test_helper.rb'
rescue LoadError
  require 'test_helper'
end

class ListTest < ActiveSupport::TestCase
  def setup
    setup_db
    (1..4).each { |counter| ListMixin.create! :pos => counter, :parent_id => 5 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    ListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_next_prev
    assert_equal ListMixin.find(2), ListMixin.find(1).lower_item
    assert_nil ListMixin.find(1).higher_item
    assert_equal ListMixin.find(3), ListMixin.find(4).higher_item
    assert_nil ListMixin.find(4).lower_item
  end

  def test_injection
    item = ListMixin.new(:parent_id => 1)
    assert_equal ["parent_id = 1"], item.scope_condition    
    assert_equal "pos", item.position_column
  end

  def test_insert    
    new = ListMixin.create(:parent_id => 20)
    # insert as last    
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 0)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_insert_at 
    # insert as last    
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos

    new4 = ListMixin.create(:parent_id => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ListMixin.create(:parent_id => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos

    ListMixin.find(1).destroy

    assert_equal [3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(3).pos
    assert_equal 2, ListMixin.find(4).pos
  end

  def test_with_string_based_scope
    new = ListWithStringScopeMixin.create(:parent_id => 500)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_nil_scope
    new1, new2, new3 = ListMixin.create, ListMixin.create, ListMixin.create
    new2.move_higher
    assert_equal [new2, new1, new3], ListMixin.find(:all, :conditions => 'parent_id IS NULL', :order => 'pos')
  end

  def test_remove_from_list_should_then_fail_in_list? 
    assert_equal true, ListMixin.find(1).in_list?
    ListMixin.find(1).remove_from_list
    assert_equal false, ListMixin.find(1).in_list?
  end 

  def test_remove_from_list_should_set_position_to_nil 
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).remove_from_list 

    assert_equal [2, 1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1,   ListMixin.find(1).pos
    assert_equal nil, ListMixin.find(2).pos
    assert_equal 2,   ListMixin.find(3).pos
    assert_equal 3,   ListMixin.find(4).pos
  end 

  def test_move_to_lower_in_list
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    item = ListMixin.find(2)
    item.move_to(3)
    assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    item.move_to(7)
    assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    assert_equal 4, item.pos
  end

  def test_move_to_higher_in_list
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    item = ListMixin.find(2)
    item.move_to(1)
    assert_equal [2, 1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)    
    item.move_to(-2)
    assert_equal [2, 1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    assert_equal 1, item.pos
  end

  def test_remove_before_destroy_does_not_shift_lower_items_twice 
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).remove_from_list 
    ListMixin.find(2).destroy 

    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos
  end

  def test_should_not_trigger_unexpected_callbacks_on_destroy
    element = ListMixin.find(2)
    assert !element.before_save_triggered
    element.destroy
    assert !element.before_save_triggered
  end

  # special thanks to openhood on github
  def test_delete_middle_with_holes
    # first we check everything is at expected place
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    # then we create a hole in the list, say you're working with existing data in which you already have holes
    # or your scope is very complex
    ListMixin.delete(2)

    # we ensure the hole is really here
    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    assert_equal 1, ListMixin.find(1).pos
    assert_equal 3, ListMixin.find(3).pos
    assert_equal 4, ListMixin.find(4).pos

    # can we retrieve lower item despite the hole?
    assert_equal 3, ListMixin.find(1).lower_item.id

    # can we move an item lower jumping more than one position?
    ListMixin.find(1).move_lower
    assert_equal [3, 1, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(1).pos
    assert_equal 4, ListMixin.find(4).pos

    # create another hole
    ListMixin.delete(1)

    # can we retrieve higher item despite the hole?
    assert_equal 3, ListMixin.find(4).higher_item.id

    # can we move an item higher jumping more than one position?
    ListMixin.find(4).move_higher
    assert_equal [4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    assert_equal 2, ListMixin.find(4).pos
    assert_equal 3, ListMixin.find(3).pos
  end
end
