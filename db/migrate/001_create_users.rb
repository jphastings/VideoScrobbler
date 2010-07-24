class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |table|
      table.string :username
      table.string :email
      table.string :passhash
      
      table.datetime :created_at
    end
  end
  
  def self.down
    drop_table :users
  end
end