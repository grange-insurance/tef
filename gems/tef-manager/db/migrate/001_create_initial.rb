# Create the initial tables
class CreateInitial < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.column :task_type, :string, null: true
      t.column :guid, :string, null: false
      t.column :priority, :int, null: false, default: 5
      t.column :dispatched, :datetime, null: true
      t.column :task_data, :text, null: true
    end

    add_index :tasks, :guid
    add_index :tasks, :dispatched
    add_index :tasks, :task_type

    create_table :task_resources do |t|
      t.belongs_to :task
      t.column :resource_name, :string, null: false
    end

    add_index :task_resources, :task_id
    add_index :task_resources, :resource_name
  end

  def self.down
    drop_table :tasks
    drop_table :task_resources
  end
end
