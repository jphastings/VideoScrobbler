require 'app'
sessioned = Rack::Session::Pool.new(
  Sinatra::Application,
#  :domain       => 'example.com',
  :expire_after => 60 * 60 * 24 * 365 # expire after 1 year
)
run sessioned