require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"
require "redcarpet"
require "securerandom"

set :erb, :escape_html => false
set :environment, :development
set :static_cache_control, [:no_store, :no_cache]

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(64)
  set :public_folder, File.expand_path("../public", __FILE__)
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
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
  return nil unless (1..30).cover(name.length)
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index
end

get "/new" do
  erb :new
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

get "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post "/:filename" do
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

post "/new" do
  if validate_name(params[:content])
    file_path = File.join(data_path, params[:content])

    File.write(file_path)

    session[:message] = "#{params[:filename]} was created." 
  
    redirect "/"

  else
    session[:message] = "A name is required." 
  
    redirect "/new"
  end
end