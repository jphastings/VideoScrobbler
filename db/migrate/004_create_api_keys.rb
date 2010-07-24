class CreateApiKeys < ActiveRecord::Migration
  def self.up
    create_table :api_keys do |table|
      table.integer :user_id
      table.string  :api_key
      table.string  :secret
      table.string  :app_name
      table.text    :description
      
      table.datetime :updated_at
    end
  end
  
  def self.down
    drop_table :api_keys
  end
end