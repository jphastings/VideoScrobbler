require 'active_record'
require 'digest/md5'
require 'time'
require 'uuid'

ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))[ENV['ENVIRONMENT'] || 'production'])

class User < ActiveRecord::Base
  has_many :api_keys
  has_many :library_entries
  has_many :videos, :through => :library_entries
  #Friendships
  has_many :friendships
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :friend_requests, :through => :inverse_friendships, :source => :user

  # login can be either username or email address
  def self.authenticate(login, pass)
    find_by_username_and_passhash(login,self.hash(pass)) || find_by_email_and_passhash(login,self.hash(pass))
  end
  
  def self.hash(password)
    Digest::MD5.hexdigest('k<j|h104*('+password)
  end
  
  def self.validate_username(username)
    !username.match(/^[\w_]{4,24}$/i).nil?
  end
end

class Video < ActiveRecord::Base
  has_many :users, :through => :library_entries
end

class LibraryEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :video
end

class ApiKey < ActiveRecord::Base
  belongs_to :user
  has_many :session_keys
  after_create :generate_keys
  
  def generate_keys
    write_attribute(:key,UUID.new.generate(:compact))
    write_attribute(:secret,UUID.new.generate(:compact))
  end
end

class SessionKey < ActiveRecord::Base
  belongs_to :api_key
  after_create :refresh_key
  
  def refresh_key
    write_attribute(:key,UUID.new.generate(:compact))
  end
  
  def set_user(user)
    write_attribute(:user_id,user.id)
  end
  
  def user
    return nil if read_attribute(:user_id).nil?
    User.find_by_id(read_attribute(:user_id))
  end
end

class Friendship < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, :class_name => 'User'
end