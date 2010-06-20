require 'rubygems'
require 'test/unit'
require 'active_record'
$:.unshift "#{File.dirname(__FILE__)}/../lib/"
require 'ar_acts_as_list_r3'
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :pos, :integer
      t.column :parent_id, :integer
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end

    create_table :sti_mixins do |t|
      t.column :position, :integer
      t.column :type, :string
    end   
    
    create_table :mixin_with_strings do |t|
      t.column :id, :string
      t.column :pos, :integer
      t.column :parent_id, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end   
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

module DefaultBehavior
  before_create :add_to_list_bottom_when_necessary  

  def self.table_name 
    "mixins" 
  end

  attr_accessor :before_save_triggered
  before_save :log_before_save  
  before_create :add_to_list_bottom_when_necessary

  def log_before_save
    self.before_save_triggered = true
  end
end

class Mixin < ActiveRecord::Base  
  include DefaultBehavior
end

class MixinWithStrings < ActiveRecord::Base
  acts_as_list :column => "pos", :scope => :parent
end

class ListMixin < Mixin
  acts_as_list :column => "pos", :scope => :parent  
end

class ListMixinSub1 < ListMixin
end

class ListMixinSub2 < ListMixin
end

class ListWithStringScopeMixin < Mixin
  acts_as_list :column => "pos", :scope => 'parent_id = #{parent_id}'
end

class StiMixin < Mixin
  acts_as_list
end

class StiMixinSub1 < StiMixin
end

class StiMixinSub2 < StiMixin
end
