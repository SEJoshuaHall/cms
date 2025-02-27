require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubi"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
  set :views, File.join(settings.public_folder, 'views')
end

helpers do

end

before do

end

get "/" do
  erb :home, layout: :layout
end