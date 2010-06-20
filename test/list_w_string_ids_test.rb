# Load the plugin's test_helper (Rails 2.x needs the path)
begin
  require File.dirname(__FILE__) + '/test_helper.rb'
rescue LoadError
  require 'test_helper'
end
require 'test/helper'

class ListWithStringIdsTest < ActiveSupport::TestCase

  def setup
    setup_db
    (1..4).each do |counter|
      m = MixinWithStrings.new(:pos => counter, :parent_id => 5)
      m.id = counter.to_s
      m.save!
    end
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    MixinWithStrings.find(2).move_lower
    assert_equal [1, 3, 2, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    MixinWithStrings.find(2).move_higher
    assert_equal [1, 2, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    MixinWithStrings.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    MixinWithStrings.find(1).move_to_top
    assert_equal [1, 2, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    MixinWithStrings.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    MixinWithStrings.find(4).move_to_top
    assert_equal [4, 1, 3, 2], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    MixinWithStrings.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_next_prev
    assert_equal MixinWithStrings.find(2), MixinWithStrings.find(1).lower_item
    assert_nil MixinWithStrings.find(1).higher_item
    assert_equal MixinWithStrings.find(3), MixinWithStrings.find(4).higher_item
    assert_nil MixinWithStrings.find(4).lower_item
  end

  def test_injection
    item = MixinWithStrings.new(:parent_id => 1)
    assert_equal ["parent_id = ?", 1], item.scope_condition
    assert_equal "pos", item.position_column
  end

  def test_insert
    new = MixinWithStrings.create(:parent_id => 20)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

    new = MixinWithStrings.create(:parent_id => 20)
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?

    new = MixinWithStrings.create(:parent_id => 20)
    assert_equal 3, new.pos
    assert !new.first?
    assert new.last?

    new = MixinWithStrings.create(:parent_id => 0)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_insert_at
    new = MixinWithStrings.create(:parent_id => 20)
    assert_equal 1, new.pos

    new = MixinWithStrings.create(:parent_id => 20)
    assert_equal 2, new.pos

    new = MixinWithStrings.create(:parent_id => 20)
    assert_equal 3, new.pos

    new4 = MixinWithStrings.create(:parent_id => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = MixinWithStrings.create(:parent_id => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    MixinWithStrings.find(2).destroy

    assert_equal [1, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, MixinWithStrings.find(1).pos
    assert_equal 2, MixinWithStrings.find(3).pos
    assert_equal 3, MixinWithStrings.find(4).pos

    MixinWithStrings.find(1).destroy

    assert_equal [3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, MixinWithStrings.find(3).pos
    assert_equal 2, MixinWithStrings.find(4).pos
  end

  def test_with_string_based_scope
    new = ListWithStringScopeMixin.create(:parent_id => 500)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_nil_scope
    new1, new2, new3 = MixinWithStrings.create, MixinWithStrings.create, MixinWithStrings.create
    new2.move_higher
    assert_equal [new2, new1, new3], MixinWithStrings.find(:all, :conditions => 'parent_id IS NULL', :order => 'pos')
  end
  
  
  def test_remove_from_list_should_then_fail_in_list?
    assert_equal true, MixinWithStrings.find(1).in_list?
    MixinWithStrings.find(1).remove_from_list
    assert_equal false, MixinWithStrings.find(1).in_list?
  end
  
  def test_remove_from_list_should_set_position_to_nil
    assert_equal [1, 2, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    MixinWithStrings.find(2).remove_from_list
  
    assert_equal [2, 1, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    assert_equal 1, MixinWithStrings.find(1).pos
    assert_equal nil, MixinWithStrings.find(2).pos
    assert_equal 2, MixinWithStrings.find(3).pos
    assert_equal 3, MixinWithStrings.find(4).pos
  end
  
  def test_remove_before_destroy_does_not_shift_lower_items_twice
    assert_equal [1, 2, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    MixinWithStrings.find(2).remove_from_list
    MixinWithStrings.find(2).destroy
  
    assert_equal [1, 3, 4], MixinWithStrings.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    assert_equal 1, MixinWithStrings.find(1).pos
    assert_equal 2, MixinWithStrings.find(3).pos
    assert_equal 3, MixinWithStrings.find(4).pos
  end
  
end