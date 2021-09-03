require "sinatra"
require "sinatra/reloader" if development?
require 'sinatra/content_for'
require "tilt/erubis"
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  root = File.expand_path("..", __FILE__)
  @files = Dir.glob(root + "/data/*").map do |path|
    name = File.basename(path)
    { path: path, name: name }
  end
end

get '/' do
  erb :index, layout: :layout
end

def file_data_by_name(file_name)
  @files.find { |info| info[:name] == file_name }
end

def render_file(file_name, contents)
  if File.extname(file_name) == ".md"
    content_type :html
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    return markdown.render(contents)
  else
    content_type :text
    return contents
  end
end

get '/:file_name' do
  file_name = params[:file_name]
  if file = file_data_by_name(file_name)
    contents = File.read(file[:path])
    render_file(file_name, contents)
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end
end
