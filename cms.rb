require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubi"
require "redcarpet"
require "securerandom"
require "fileutils"
require "yaml"
require "bcrypt"

set :erb, :escape_html => false
set :environment, ENV["RACK_ENV"] || :development
set :static_cache_control, [:no_store, :no_cache]

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(64)
  set :public_folder, File.expand_path("../public", __FILE__)
  path = data_path
  FileUtils.mkdir_p(path) unless Dir.exist?(path)
  FileUtils.chmod(0755, path) if File.exist?(path)
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    render_markdown(content)
  end
end

def validate_name(name)
  !name.empty? && (1..30).cover?(name.length)
end

def validate_login
  return true if session[:username]
  session[:message] = "You must be signed in to do that."
  redirect '/'
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index
end

get "/new" do
  validate_login
  erb :new
end

post "/create" do
  validate_login
  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "A name is required."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created."

    redirect "/"
  end
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  credentials = load_user_credentials
  username = params[:username]

  if credentials.key?(username) && BCrypt::Password.new(credentials[username]) == params[:password]
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session[:username] = nil
  session[:message] = "You have been signed out." 
  redirect "/" 
end

get "/:filename/edit" do
  validate_login
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post "/:filename/delete" do
  validate_login
  file_path = File.join(data_path, params[:filename]) 
  File.delete(file_path)
  session[:message] = "#{params[:filename]} has been deleted." 

  redirect "/"
end

get "/:filename" do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

post "/:filename" do
  validate_login
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end