class CreateFriendships < ActiveRecord::Migration
  def self.up
    create_table :friendships do |table|
      table.integer  :user_id
      table.integer  :friend_id
      table.datetime :created_at
    end
  end
  
  def self.down
    drop_table :friendships
  end
end