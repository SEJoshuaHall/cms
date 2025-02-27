require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubi"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

helpers do

end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end