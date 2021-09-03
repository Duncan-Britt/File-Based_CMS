require "sinatra"
require "sinatra/reloader" if development?
require 'sinatra/content_for'
require "tilt/erubis"

configure do
  # enable :sessions
  # set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  @files = Dir.glob('data/*.txt').map do |path|
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

get '/data/:file_name' do
  file_name = params[:file_name]
  content_type :text
  file = file_data_by_name(file_name)
  File.read(file[:path])
end
