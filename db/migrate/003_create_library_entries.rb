class CreateLibraryEntries < ActiveRecord::Migration
  def self.up
    create_table :library_entries do |table|
      table.integer :user_id
      table.integer :video_id
      table.float   :position, :default => 0, :null => false
      table.float   :start, :default => 0, :null => false
      table.string  :state, :default => 's'
      table.boolean :loved, :default => false, :null => false
      table.string  :origin
      
      table.datetime :updated_at
    end
  end
  
  def self.down
    drop_table :library_entries
  end
end