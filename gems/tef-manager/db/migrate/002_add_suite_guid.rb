# Add a suite_guid so bulk operations can be supported
class AddSuiteGuid < ActiveRecord::Migration
  def self.up
    change_table :tasks do |t|
      t.column :suite_guid, :string, null: true
    end

    add_index :tasks, :suite_guid
  end

  def self.down
    change_table :tasks do |t|
      t.remove :suite_guid
    end
  end
end
