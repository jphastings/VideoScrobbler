require 'rubygems'
require 'sinatra'
require 'haml'
require 'yaml'
require 'db'

enable :sessions

before do
  @javascript = []
end

helpers do
  def get_url(remote_id)
    ids = remote_id.split(":")
    case ids[0]
    when "tvdb"
      "http://thetvdb.com/?tab=episode&id=#{ids[1]}"
    when "tmdb"
      "http://www.themoviedb.org/movie/#{ids[1]}"
    else
      remote_id
    end
  end
end

## Static pages
get '/' do
  haml :home
end

get '/account' do
  halt(401,{:error =>7,:message=>"Not authenticated"}) if session[:autheduser].nil?
  haml :account
end

#### Authentication
get '/auth' do
  haml :login_signup, :locals => {:noauth => true}
end

get '/login' do; redirect '/auth#login'; end
get '/signup' do; redirect '/auth#signup'; end
get '/logout' do; redirect '/auth'; end

# User-facing HTML that allows them to accept that an application will have private access to their data
get '/api/auth' do
  haml :allow_access
end

# Allows people to sign up for API accounts
get '/api/account' do
  haml :get_api
end

get '/api/docs' do
  haml :api_docs
end

get '/users/:username' do
  user = User.find_by_username(params[:username])
  halt(404,"User not found!") if user.nil?
  haml :user, :locals => {:user => user}
end


### Actions
get '/action.json' do
  case params['action']
  when 'testusername'
    User.validate_username(params['username']) and User.find_by_username(params['username']).nil?
  when 'login'
    if (session[:autheduser] = User.authenticate(params['username'],params['password'])).nil?
      halt(401,{:error =>7,:message=>"Invalid Password"})
    else
      # TODO: Redirect to /user/:username as well as returning this?
      {:action => :login,:username=>session[:autheduser].username,:status => :ok}
    end
  when 'signup'
    # I know there's much easier ways to do this with validates_on etc. but I can't be sure it'll work so I'm doing it like this…
    # Feel free to correct it if you know what you're doing!
    halt(400,{:error =>7,:message=>"Passwords do not match"}.to_json) if params['password'] != params['confirm-password']
    halt(400,{:error =>7,:message=>"Username not available"}.to_json) if !(User.validate_username(params['username']) and User.find_by_username(params['username']).nil?)
    halt(400,{:error =>7,:message=>"Email invalid"}.to_json) if not (params['email'] =~ /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i)
    halt(400,{:error =>7,:message=>"Email already in use"}.to_json) if !User.find_by_email(params['email']).nil?
    
    user = User.new(:username => params['username'],:passhash => User.hash(params['password']),:email=>params['email'])
        
    halt(500,"New user could not be generated, please try again later") if !user.save
    {:action => :signup,:username=>user.username,:status => :ok}
  when 'changepw'
    halt(401,{:error =>7,:message=>"Not authenticated"}.to_json) if session[:autheduser].nil?
    halt(401,{:error =>7,:message=>"Incorrect password"}.to_json) if session[:autheduser].passhash != User.hash(params['oldpassword'])
    
    session[:autheduser].passhash = User.hash(params['password'])
    session[:autheduser].save
    {:action => :changepw, :status => :ok, :message => "Password changed"}
  else
    halt(400, "No such action")
  end.to_json
end

# The API forwarder
get '/api/1.0/' do
  require 'api'
  
  begin
    VideoScrobblerApi.process(params)
  rescue VideoScrobblerApi::ApiError => e
    halt(e.class::HTTP,{
      :error => e.class::Code,
      :message => e.message
    })
  end.to_json
end