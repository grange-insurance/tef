# Add a suite_guid so bulk operations can be supported
class AddTimeLimit < ActiveRecord::Migration
  def self.up
    change_table :tasks do |t|
      t.column :time_limit, :int, null: true
    end
  end

  def self.down
    change_table :tasks do |t|
      t.remove :time_limit
    end
  end
end
