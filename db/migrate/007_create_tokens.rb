class CreateTokens < ActiveRecord::Migration
  def self.up
    create_table :tokens do |table|
      table.integer :api_key_id
      table.string  :user_id,:default => nil
      table.string  :key
      
      table.datetime :created_at
    end
  end
  
  def self.down
    drop_table :tokens
  end
end