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
  file_path = File.join(@root, 'data', @file_name)

  if File.exist?(file_path)
    file_content = File.read(file_path)

    if @file_name.end_with?(".md")
      content_type :html
      render_markdown(file_content)
    else
      headers["Content-Type"] = "text/plain"
      file_content
    end
  else
    session[:message] = "#{@file_name} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  file_path = @root + "/data/" + params[:filename]

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post "/:filename" do
  file_path = @root + "/data/" + params[:filename]

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end