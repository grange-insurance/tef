# Add a task status so that tasks can be paused, etc.
class AddTaskStatus < ActiveRecord::Migration
  def self.up
    add_column :tasks, :status, :string, null: true
  end

  def self.down
    remove_column :tasks, :status
  end
end
