require "sinatra"
require "sinatra/contrib"
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
  @root = File.expand_path("..", __FILE__)
end

get "/" do
  @files = Dir.glob(@root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :index, layout: :layout
end

get "/:file_name" do
  @file_name = params[:file_name]

  headers["Content-Type"] = "text/plain"
  File.read(@file_name)
end
