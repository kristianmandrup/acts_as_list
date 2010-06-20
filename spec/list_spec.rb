require File.dirname(__FILE__) + '/spec_helper'

class ListTest
  class << self
    def before_destroy(*attr); end
    def before_create(*attr); end
  end

  include ActiveRecord::Acts::List
  acts_as_list :scope => :parent

  attr_accessor :position, :attr1, :attr2
end

describe ActiveRecord::Acts::List do

  before do
    @elem = ListTest.new
    @list = []
  end

  describe "insert at bottom" do
    it "should insert the element at the bottom of the list" do
      @elem.should_receive :assume_bottom_position
      @elem.insert_at_bottom
    end
  end

  describe "insert into" do
    before do
      @elem.stub! :update_attribute
    end

    it "should insert the element at the bottom" do
      @list.should_receive(:insert).with(0, @elem)
      @elem.insert_into @list
    end

    it "should set all the optional attributes to the given value" do
      @elem.insert_into @list, :attr1 => "value1", :attr2 => "value2"
      @elem.attr1.should == "value1"
      @elem.attr2.should == "value2"
    end

    it "should insert into a specified position" do
      @list.should_receive(:insert).with(41, @elem)
      @elem.insert_into @list, :position => 41
    end

    it "should update the position on all attributes in the list" do
      @elem2 = ListTest.new
      @list = [@elem2]

      @elem.should_receive(:update_attribute).with(:position, 2)
      @elem2.should_receive(:update_attribute).with(:position, 1)

      @elem.insert_into @list, :position => 1
    end
  end

  describe "remove from" do
    it "should not do anything if the elem is not in the list" do
      @elem.should_not_receive :decrement_positions_on_lower_items
      @elem.remove_from @list
    end

    describe "in list" do
      before do
        @list = [@elem]
        @elem.position = 1
        @elem.stub! :decrement_positions_on_lower_items
      end

      it "should decrement the position on all lower items" do
        @elem.should_receive :decrement_positions_on_lower_items
        @elem.remove_from @list
      end

      it "should set the position to nil" do
        @elem.remove_from @list
        @elem.position.should be_nil
      end

      it "should delete the element from the list" do
        @elem.remove_from @list
        @list.should_not include(@elem)
      end

      it "should set all the optional attributes to the given value" do
        @elem.remove_from @list, :attr1 => "unset1", :attr2 => "unset2"
        @elem.attr1.should == "unset1"
        @elem.attr2.should == "unset2"
      end
    end
  end

  { "higher_items" => :<, "lower_items" => :> }.each do |items, operator|
    describe items do
      it "should return nil if the element is not in the list" do
        @elem.send(items).should be_nil
      end

      it "should find all #{items} with a ActiveRecord finder" do
        @elem.position = 23
        @elem.stub!(:scope_condition).and_return "scope"
        ListTest.should_receive(:find).with :all, :conditions => "scope AND position #{operator} 23"

        @elem.send items
      end
    end
  end
end