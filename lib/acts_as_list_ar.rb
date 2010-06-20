# from http://github.com/goncalossilva/acts_as_list/
module ActsAsListAR  
  def scope_name
    "named_scope"
  end  

  def acts_as_list(options = {})
    raise ArgumentError, "Hash expected, got #{options.class.name}" if !options.is_a?(Hash) && !options.empty?        
    configuration = { :column => "position", :scope => "'deleted_at IS NULL OR deleted_at IS NOT NULL'" }
    configuration.update(options) if options.is_a?(Hash)

    configuration[:scope] = "#{configuration[:scope]}_id".intern if configuration[:scope].is_a?(Symbol) && configuration[:scope].to_s !~ /_id$/

    if configuration[:scope].is_a?(Symbol)
      scope_condition_method = %(
        def scope_condition
          if #{configuration[:scope].to_s}.nil?
            "#{configuration[:scope].to_s} IS NULL"
          else
            ["#{configuration[:scope].to_s} = ?", #{configuration[:scope].to_s}]                
          end
        end
      )
    else
      scope_condition_method = "def scope_condition() \"#{configuration[:scope]}\" end"
    end

    class_eval <<-EOV   
      def self.with_acts_as_list_scope(scope_conditions)
        clazz = self # not sure this works!
        with_scope :find => {:conditions => scope_conditions} do
          if block
            block.arity < 1 ? clazz.instance_eval(&block) : block.call(clazz) 
          end
        end
      end            

      def acts_as_list_class
        self.class
      end

      def position_column
        '#{configuration[:column]}'
      end

      #{scope_condition_method}

      before_destroy :eliminate_current_position
      before_create  :add_to_list_bottom_when_necessary 
    EOV
    
    include InstanceMethods
  end
  
  # All the methods available to a record that has had <tt>acts_as_list</tt> specified. Each method works
  # by assuming the object to be the item in the list, so <tt>chapter.move_lower</tt> would move that chapter
  # lower in the list of all chapters. Likewise, <tt>chapter.first?</tt> would return +true+ if that chapter is
  # the first in the list of all chapters.
  module InstanceMethods
    # Insert the item at the given position (defaults to the top position of 1).
    def insert_at(position = 1)
      insert_at_position(position)
    end

    # Inserts the item at the bottom of the list
    def insert_at_bottom
      assume_bottom_position
    end

    def insert_into(list, options = {})
      position = options.delete(:position) || list.size
      options.each { |attr, value| self.send "#{attr}=", value }

      list.insert(position, self)
      list.each_with_index { |item, index| item.update_attribute(:position, index + 1) }
    end
    
    def move_to(position = 1)
      move_to_position(position)
    end

    def remove_from(list, options = {})
      if in_list?
        decrement_positions_on_lower_items

        self.send "#{position_column}=", nil
        options.each { |attr, value| self.send "#{attr}=", value }
        list.delete self
      end
    end    

    # Swap positions with the next lower item, if one exists.
    def move_lower
      lower = lower_item
      return unless lower
      acts_as_list_class.transaction do
        self.update_attribute(position_column, lower.send(position_column))
        lower.decrement_position
      end
    end

    # Swap positions with the next higher item, if one exists.
    def move_higher
      higher = higher_item
      return unless higher
      acts_as_list_class.transaction do
        self.update_attribute(position_column, higher.send(position_column))
        higher.increment_position
      end
    end

    # Move to the bottom of the list. If the item is already in the list, the items below it have their
    # position adjusted accordingly.
    def move_to_bottom
      # return unless in_list?
      acts_as_list_class.transaction do
        decrement_positions_on_lower_items if in_list?
        assume_bottom_position
      end
    end

    # Move to the top of the list. If the item is already in the list, the items above it have their
    # position adjusted accordingly.
    def move_to_top
      # return unless in_list?
      acts_as_list_class.transaction do
        # increment_positions_on_higher_items
        in_list? ? increment_positions_on_higher_items : increment_positions_on_all_items
        assume_top_position
      end
    end

    # Removes the item from the list.
    def remove_from_list
      # if in_list?
      #   decrement_positions_on_lower_items
      #   update_attribute position_column, nil
      # end            
      return unless in_list?
      decrement_positions_on_lower_items
      update_attribute position_column, nil        
    end

    # Increase the position of this item without adjusting the rest of the list.
    def increment_position
      # return unless in_list?
      update_attribute position_column, self.send(position_column).to_i + 1
    end

    # Decrease the position of this item without adjusting the rest of the list.
    def decrement_position
      # return unless in_list?
      update_attribute position_column, self.send(position_column).to_i - 1
    end

    # Return +true+ if this object is the first in the list.
    def first?
      # return false unless in_list?
      self.send(position_column) == 1
    end

    # Return +true+ if this object is the last in the list.
    def last?
      # return false unless in_list?
      self.send(position_column) == bottom_position_in_list
    end
    
    # Return the next higher item in the list.
    def higher_item
      # return nil unless in_list?  # http://github.com/brightspark3/acts_as_list/commit/8e55352aaa437d23a1ebdeabd5276c6dd5aad6a1      
      acts_as_list_class.find(:first, :conditions =>
        "#{scope_condition} AND #{position_column} < #{send(position_column).to_s}", :order => "#{position_column} DESC"
      )                           
    end

    # Return the next lower item in the list.
    def lower_item
      # return nil unless in_list?
      acts_as_list_class.find(:first, :conditions => 
        "#{scope_condition} AND #{position_column} > #{send(position_column).to_s}", :order => "#{position_column} ASC"
      )
    end    

    # Test if this record is in a list
    def in_list?
      !send(position_column).nil?
    end

    private
      def add_to_list_top
        increment_positions_on_all_items
      end

      def add_to_list_bottom
        self[position_column] = bottom_position_in_list.to_i + 1
      end
      
      def add_to_list_bottom_when_necessary
        self[position_column] = bottom_position_in_list.to_i + 1 if send(position_column).nil?
      end      

      # Overwrite this method to define the scope of the list changes
      def scope_condition() "1" end

      # Returns the bottom position number in the list.
      #   bottom_position_in_list    # => 2
      def bottom_position_in_list(except = nil)
        item = bottom_item(except)
        item ? item.send(position_column) : 0
      end

      # Returns the bottom item
      def bottom_item(except = nil)
        conditions = scope_condition
        conditions = "#{conditions} AND #{self.class.primary_key} != #{except.id}" if except
        acts_as_list_class.find(:first, :conditions => conditions, :order => "#{position_column} DESC")
      end

      # Forces item to assume the bottom position in the list.
      def assume_bottom_position
        update_attribute(position_column, bottom_position_in_list(self).to_i + 1)
      end

      # Forces item to assume the top position in the list.
      def assume_top_position
        update_attribute(position_column, 1)
      end

      # This has the effect of moving all the higher items up one.
      def decrement_positions_on_higher_items(position)
        acts_as_list_class.update_all("#{position_column} = (#{position_column} - 1)", "#{scope_condition} AND #{position_column} <= #{position}")     
        # acts_as_list_class.with_acts_as_list_scope(scope_condition) do
        #   update_all("#{position_column} = (#{position_column} - 1)", "#{position_column} <= #{position}")
        # end          
      end

      # This has the effect of moving all the lower items up one.
      def decrement_positions_on_lower_items
        return unless in_list?
        acts_as_list_class.update_all("#{position_column} = (#{position_column} - 1)", "#{scope_condition} AND #{position_column} > #{send(position_column).to_i}")          
        # acts_as_list_class.with_acts_as_list_scope(scope_condition) do
        #   update_all("#{position_column} = (#{position_column} - 1)", "#{position_column} > #{send(position_column).to_i}")
        # end          
      end

      # This has the effect of moving all the higher items down one.
      def increment_positions_on_higher_items
        return unless in_list?
        acts_as_list_class.update_all("#{position_column} = (#{position_column} + 1)", "#{scope_condition} AND #{position_column} < #{send(position_column).to_i}")      
        # acts_as_list_class.with_acts_as_list_scope(scope_condition) do
        #   update_all("#{position_column} = (#{position_column} + 1)", "#{position_column} < #{send(position_column).to_i}")
        # end          
      end

      # This has the effect of moving all the lower items down one.
      def increment_positions_on_lower_items(position)
        acts_as_list_class.update_all("#{position_column} = (#{position_column} + 1)", "#{scope_condition} AND #{position_column} >= #{position}")
        # acts_as_list_class.with_acts_as_list_scope(scope_condition) do
        #   update_all("#{position_column} = (#{position_column} + 1)", "#{position_column} >= #{position}")
        # end         
      end

      # Increments position (<tt>position_column</tt>) of all items in the list.
      def increment_positions_on_all_items
        acts_as_list_class.update_all("#{position_column} = (#{position_column} + 1)",  "#{scope_condition}")
        # acts_as_list_class.with_acts_as_list_scope(scope_condition) do            
        #   update_all("#{position_column} = (#{position_column} + 1)")
        # end          
      end

      def insert_at_position(position)
        remove_from_list
        increment_positions_on_lower_items(position)
        self.update_attribute(position_column, position)
      end


      # This has the effect of moving all items between two positions (inclusive) up one.
      def decrement_positions_between(low, high)
        acts_as_list_class.update_all(
          "#{position_column} = (#{position_column} - 1)", ["#{scope_condition} AND #{position_column} >= ? AND #{position_column} <= ?", low, high]
        )
      end

      # This has the effect of moving all items between two positions (inclusive) down one.
      def increment_positions_between(low, high)
        acts_as_list_class.update_all(
          "#{position_column} = (#{position_column} + 1)", ["#{scope_condition} AND #{position_column} >= ? AND #{position_column} <= ?", low, high]
        )
      end

      # Moves an existing list element to the "new_position" slot.
      def move_to_position(new_position)
       old_position = self.send(position_column)
       unless new_position == old_position
         if new_position < old_position
           # Moving higher in the list (up) 
           new_position = [1, new_position].max
           increment_positions_between(new_position, old_position - 1)
         else
           # Moving lower in the list (down)
           new_position = [bottom_position_in_list(self).to_i, new_position].min
           decrement_positions_between(old_position + 1, new_position)
         end
         self.update_attribute(position_column, new_position)
       end
      end

      def eliminate_current_position
        decrement_positions_on_lower_items if in_list?
      end  
  end
end

# Use appropriate ActiveRecord methods
if not defined?(Rails) or Rails::VERSION::MAJOR == 2
  require 'acts_as_list_ar/rails2'
elsif Rails::VERSION::MAJOR == 3
  require 'acts_as_list_ar/rails3'
else
  raise Exception, "Rails 2.x or Rails 3.x expected, got Rails #{Rails::VERSION::MAJOR}.x"
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.extend ActsAsListAR

