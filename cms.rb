require "sinatra"
require "sinatra/contrib"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubi"
require "securerandom"

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(32) }
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

  if File.exist?(File.join(@root, 'data', @file_name))
    headers["Content-Type"] = "text/plain"
    File.read(File.join("data", @file_name))
  else
    session[:message] = "#{@file_name} does not exist."
    redirect "/"
  end
end
