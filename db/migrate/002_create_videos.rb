class CreateVideos < ActiveRecord::Migration
  def self.up
    create_table :videos do |table|
      table.string :remote_id
      table.string :video_type
    end
  end
  
  def self.down
    drop_table :videos
  end
end