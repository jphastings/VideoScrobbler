# This module expects the database to be already required

# The Video Scrobbler AAPI
class VideoScrobblerApi
  # Process the incoming call and pass it out to the methods
  def self.process(params)
    #raise InvalidParameters, "The request is missing parameters" if !params.include?([:api_key]) or !params.include?([:api_sig]) or !params.include?([:method]) or (!params.include?([:sk]) and !['auth.getToken','auth.getSession'].inlude?(params[:method]))
    sig = params.delete('api_sig')
    
    api = ApiKey.find_by_api_key(params['api_key'])
    raise InvalidAPIKey if api.nil?
    raise InvalidSignature if sig != Digest::MD5.hexdigest(params.sort.flatten.join()+api.secret)
    
    params[:api] = api
    
    method = params.delete('method').split(".")
  
    if method[0].downcase != 'auth'
      session = SessionKey.find_by_api_key_id_and_key(params[:api].id,params.delete('sk'))
      raise InvalidSessionKey, "This session key isn't valid" if session.nil?
      params[:autheduser] = session.user
    else
      params[:autheduser] = nil
    end
    
    #begin
      raise NoMethodError if not ['Auth','Video','User'].include?(method[0].capitalize)
      self.const_get(method[0].capitalize).send(method[1].to_sym,params)
    #rescue NoMethodError => e
    #  p e
    #  raise InvalidMethod
    #end
  end
  
  class ApiError < RuntimeError
    Code = 8
    HTTP = 400
    def message; "Server Error. Please try again later."; end
  end
  class InvalidParameters < ApiError
    Code = 6
    def message; "Your request is missing a required parameter or a parameter is invalid"; end
  end
  class InvalidAPIKey < ApiError
    Code = 10
    def message; "This API Key is invalid"; end
  end
  class InvalidSignature < ApiError
    Code = 13
    def message; "Invalid method signature supplied"; end
  end
  class InvalidSessionKey < ApiError
    Code = 9
    def message; "Invalid session key"; end
  end
  class InvalidResource < ApiError
    Code = 7
    def message; "Invalid resource"; end
  end
  class InvalidMethod < ApiError
    Code = 3
    def message; "No method with that name in this package"; end
  end
  class NotAuthenticated < ApiError
    Code = 4
    def message; "You do not have permissions to access the service"; end
  end
  
  private
  # The Authentication methods
  class Auth
    def self.getToken(params)
      token = params[:api].tokens.create
      {:token => token.key}
    end
    
    def self.getSession(params)
      token = Token.find_by_api_key_id_and_key(params[:api].id,params['token'])
      raise(InvalidResource, "This token isn't valid") if token.nil?
      raise(NotAuthenticated, "This token has not been accepted yet") if token.user_id.nil?
      sk = params[:api].session_keys.create
      sk.user_id = token.user_id
      sk.save
      token.delete
      {
        :sk => sk.key,
        :user => sk.user.username
      }
    end
  end
  
  class Video
    States = {
      'p' => 'playing',
      'r' => 'paused',
      's' => 'stopped',
      'f' => 'finished'
    }
    
    # Returns the info about a video, allows lookup of local id from remote id
    def self.getInfo(params)
      if !params['username'].nil?
        user = ::User.find_by_username(params['username'])
        raise InvalidResource, "Unknown user requested" if user.nil?
      end
      
      video = case params['id']
      when /^\d+$/
        ::Video.find_by_id(params['id'])
      when /^([a-z]+):(.+)$/
        type = case $1
        when 'tvdb'
          "tv"
        when 'tmdb'
          "film"
        else
          "url"
        end
        ::Video.find_or_create_by_remote_id_and_video_type(params['id'],type)
      else
        nil
      end
      
      raise InvalidResource, "There is no video by that id" if video.nil?
      
      data = { # TODO: Added stats
        :id => video.id,
        :type => video.video_type,
        :remote_id => video.remote_id,
        :plays => LibraryEntry.count(:conditions => ['video_id = ? AND state = \'f\'',video.id]),
        :active => LibraryEntry.count(:conditions => ['video_id = ? AND (state = \'p\' OR state = \'r\')',video.id])
      }
      
      # If we are authenticated and are asking about a friend ()
      if params[:autheduser]
        # Get details about yourself if no user specified
        user = params[:autheduser] if params['username'].nil?
        if params[:autheduser].friends.include? user or params['username'].nil?
          recent = LibraryEntry.find(:first,:conditions => ['video_id = ? AND user_id = ?',video.id,user.id],:order => 'updated_at DESC')
          
          data.merge!({
            :user => recent.nil? ? {
              :username => user.username,
              :loved => 0,
              :plays => 0
            } : {
              :username => user.username,
              :loved => LibraryEntry.count(:conditions => ['video_id = ? AND user_id = ? AND loved = ?',video.id,user.id,true]),
              :state => (recent.state rescue nil),
              :position => (recent.position rescue nil),
              :plays => LibraryEntry.count(:conditions => ['video_id = ? AND user_id = ? AND state = \'f\'',video.id,user.id])
            }
          })
        end
      end
      
      data
    end
    
    # Allows user to love/unlove a video. Cos we all like a bit of self.love.
    def self.love(params)
      raise NotAuthenticated if params[:autheduser].nil?
      raise InvalidResource if ::Video.find_by_id(params['id']).nil?
      params['love'] = !['false','f','no','n','0'].include?(params['love'])
      # Find the most recent play of this track
      entry = LibraryEntry.find(:first,:conditions => ["user_id = ? AND video_id = ?",params[:autheduser].id,params['id']],:order=>"updated_at DESC")
      if entry.nil? # Create an entry for this video, one doesn't exist
        entry = LibraryEntry.create(:user_id =>params[:autheduser].id,:video_id => params['id'],:loved => params['love'])
      else
        entry.loved = params['love']
      end
      entry.save
      {
        :id => params['id'],
        :love => params['love']
      }
    end
    
    # Informs the server about where you are in the video you're watching
    def self.scrobble(params)
      raise NotAuthenticated if params[:autheduser].nil?
      raise InvalidResource if ::Video.find_by_id(params['id']).nil?
      raise InvalidParameter, "Position needs to be a reasonably sized integer or float" if not (params['position'] =~ /^(\d{1,5}(?:\.\d{1,2})?)/)
      params['position'] = $1
      
      params['state'] = case params['state']
      when 'playing'
        'p'
      when 'paused'
        'r'
      when 'finished', 'finnished' # cos some people can't spell :P
        'f'
      else #stopped
        's'
      end
      
      # look for an unfinished instance of this video being watched, if one is found we'll continue changing it
      entry = LibraryEntry.find(:first,:conditions => ["user_id = ? AND video_id = ? AND origin = ? AND state != 'f'",params[:autheduser].id,params['id'],params['origin']], :order => "updated_at DESC")
      fresh = entry.nil?
      
      if fresh
        entry = LibraryEntry.create(:user_id =>params[:autheduser].id,:video_id => params['id'])
        entry.start = params['position']
      end
      
      entry.state = params['state']
      entry.position = params['position']
      entry.origin = params['origin']
      entry.save
      {
        :id => entry.video_id,
        :position => entry.position,
        :state => self::States[entry.state],
        :origin => entry.origin,
        :at => entry.updated_at.to_i,
        :continued => !fresh
      }
    end
  end
  
  class User
    # Returns information about the user requested, with additional information if the person is a friend
    def self.getInfo(params)
      user = ::User.find_by_username(params['username'])
      raise InvalidResource, "Unknown user requested" if user.nil?  # TODO: Allow no user if autheduser
      
      data = {
        :username => user.username,
        :since => user.created_at
      }
      
      if !params[:autheduser].nil? and params[:autheduser].friends.include? user or user == params[:autheduser]
        data.merge!({
          :watching => LibraryEntry.find(:all,:conditions => ["user_id = ? AND (state = 'p' OR state = 'r')",user.id]).collect {|entry|
            {
              :id => entry.video_id,
              :position => entry.position,
              :state => Video::States[entry.state],
              :origin => entry.origin,
              :at => entry.updated_at
            }
          }
        })
      end
      data
    end
    
    # Returns a list of the users friends
    def self.getFriends(params)
      if params[:autheduser].nil?
        user = ::User.find_by_username(params['username'])
      end
    end
  end
end