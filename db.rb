require 'active_record'
require 'digest/md5'
require 'digest/sha1'
require 'time'

ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))[ENV['ENVIRONMENT'] || 'development'])

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
  has_many :tokens
  after_create :generate_keys
  
  def generate_keys
    write_attribute(:api_key,Digest::SHA1.hexdigest(rand(10**10).to_s + Time.now.to_f.to_s + 'salty!' + rand(10**10).to_s))
    write_attribute(:secret, Digest::SHA1.hexdigest(rand(10**10).to_s + Time.now.to_f.to_s + 'peppery?' + rand(10**10).to_s))
    self.save
  end
end

class SessionKey < ActiveRecord::Base
  belongs_to :api_key
  before_create :generate_key
  
  def generate_key
    write_attribute(:key,Digest::SHA1.hexdigest(rand(10**10).to_s + Time.now.to_f.to_s + 'ILoveAGoodBitter' + rand(10**10).to_s))
  end
  
  def user
    return nil if read_attribute(:user_id).nil?
    User.find_by_id(read_attribute(:user_id))
  end
end

class Token < ActiveRecord::Base
  belongs_to :api_key
  before_create :generate_key
  
  def generate_key
    write_attribute(:key,Digest::SHA1.hexdigest(rand(10**10).to_s + Time.now.to_f.to_s + '~umame~' + rand(10**10).to_s))
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