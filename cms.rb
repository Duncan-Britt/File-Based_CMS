require "sinatra"
require "sinatra/reloader" if development?
require 'sinatra/content_for'
require "tilt/erubis"
require 'redcarpet'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

before do
  @files = Dir.glob(data_path + "/*").map do |path|
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
    return erb markdown.render(contents)
  else
    content_type :text
    return contents
  end
end

def credentials_guard_clause
  unless session[:credentials] == { username: 'admin', password: '$2a$12$D2naHI5pZ52Sc/0qsH4apODd6dkSW3L9ZWNhmF.imBewAQPzmMtPC' }
    session[:message] = "You must be signed in to do that."
    redirect '/'
  end
end

get '/new_document' do
  credentials_guard_clause

  erb :new_document, layout: :layout
end

get '/sign_in' do
  erb :sign_in, layout: :layout
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

get '/:file_name/edit' do
  credentials_guard_clause

  file_name = params[:file_name]
  if file = file_data_by_name(file_name)
    @contents = File.read(file[:path])

    erb :edit, layout: :layout
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end
end

post '/:file_name/edit' do
  credentials_guard_clause

  file_name = params[:file_name]
  updated_content = params[:content]
  file_data = file_data_by_name(file_name)
  file = File.open(file_data[:path], 'w')
  file.write updated_content

  file.close

  session[:message] = "#{file_name} has been updated"
  redirect '/'
end

def create_document(name, content = "")
  File.open(File.join(data_path, name), "w") do |file|
    file.write(content)
  end
end

post '/new_document' do
  credentials_guard_clause

  document_name = params[:document_name].strip
  if document_name.empty?
    session[:message] = "A name is required."
    status 422
    erb :new_document, layout: :layout
  else
    create_document document_name
    session[:message] = "#{document_name} has been created successfully"
    redirect '/'
  end
end

post '/:file_name/delete' do
  credentials_guard_clause

  file_name = params[:file_name]
  if file_data = file_data_by_name(file_name)
    File.delete(file_data[:path])
    session[:message] = "#{file_name} was deleted"
  end
  redirect '/'
end

def load_user_credentials
  path = if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load(File.read(path))
end

def correct_credentials?(username, password)
  credentials = load_user_credentials
  BCrypt::Password.new(credentials[username]) == password
end

post '/sign_in' do
  username = params[:username]
  password = params[:password]

  if correct_credentials?(username, password)
    session[:message] = "Welcome!"
    session[:credentials] = { username: username, password: password }
    redirect '/'
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :sign_in, layout: :layout
  end
end

post '/sign_out' do
  session.delete(:credentials)
  session[:message] = "You have been signed out."
  redirect '/'
end
