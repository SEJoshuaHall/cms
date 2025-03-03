require "sinatra"
require "sinatra/contrib"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubi"
require "securerandom"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(32) }
  set :erb, :escape_html => true
  set :views, File.join(settings.public_folder, 'views')
  # Make the markdown processor available to the entire application
  set :markdown, Redcarpet::Markdown.new(Redcarpet::Render::HTML)
end

helpers do
  # Helper method to render markdown
  def render_markdown(text)
    settings.markdown.render(text)
  end
end

before do

end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def load_file_content(file_path)
  content = File.read(file_path)
  file_name = File.basename(file_path)
  
  if file_name.end_with?(".md")
    content_type :html
    render_markdown(content)
  else
    content_type :text
    content
  end
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index
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