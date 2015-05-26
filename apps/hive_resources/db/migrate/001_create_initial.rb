class CreateInitial < ActiveRecord::Migration
  def self.up
    create_table :resources do |t|
      t.column :name, :string, null: false
      t.column :ref_limit, :integer, default: -1
    end

    add_index :resources, :name

    create_table :resource_windows do |t|
      t.column :resource_id, :int, null: false
      t.column :day_no, :integer, default: -1
      t.column :start_time, :string, null: false
      t.column :end_time, :string, null: false
    end
  end

  def self.down
    drop_table :resources
    drop_table :resource_windows
  end
end
