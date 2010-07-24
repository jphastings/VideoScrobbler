class CreateSessionKeys < ActiveRecord::Migration
  def self.up
    create_table :session_keys do |table|
      table.integer :api_key_id
      table.string  :user_id
      table.string  :key
      table.boolean :is_token, :default => true
      
      table.datetime :created_at
    end
  end
  
  def self.down
    drop_table :session_keys
  end
end