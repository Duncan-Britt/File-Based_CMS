ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require 'minitest/reporters'
require "rack/test"
Minitest::Reporters.use!

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def sign_in_user
    post '/sign_in', username: 'admin', password: 'secret'
    assert_equal "admin", session[:credentials][:username]
  end

  def admin_session
    { "rack.session" => { credentials: { username: 'admin', password: 'secret' }}}
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_viewing_text_document
    create_document "history.txt", "Ruby 0.95 released"

    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Ruby 0.95 released"
  end

  def test_viewing_markdown_document
    create_document "about.md", "# Ruby is..."

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_document_not_found
    get "/notafile.ext"

    assert_equal 302, last_response.status
    assert_equal "notafile.ext does not exist.", session[:message]

    get last_response["Location"]
    assert_equal 200, last_response.status
  end

  def test_editing_document
    create_document "changes.txt"

    get "/changes.txt/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_updating_document
    create_document 'changes.txt'

    post "/changes.txt/edit", {content: "new content"}, admin_session

    assert_equal 302, last_response.status
    assert_equal "changes.txt has been updated", session[:message]
    get last_response["Location"]
    assert_equal 200, last_response.status
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_new_document_form
    get '/new_document', {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Add a new document"
  end

  def test_create_new_document
    post "/new_document", {document_name: "test.txt"}, admin_session

    assert_equal 302, last_response.status
    assert_equal "test.txt has been created successfully", session[:message]
    get last_response["Location"]
    assert_equal 200, last_response.status
  end

  def test_create_new_document_without_filename
    post "/new_document", {document_name: ""}, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_delete_document
    create_document "doc.txt"
    post "/doc.txt/delete", {}, admin_session

    assert_equal 302, last_response.status
    assert_equal "doc.txt was deleted", session[:message]
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_nil session[:message]
  end

  def test_valid_sign_in
    get '/sign_in'

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_nil session[:credentials]
    post '/sign_in', username: 'admin', password: 'secret'
    refute_nil session[:credentials]
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_invalid_sign_in
    post '/sign_in', username: 'bo', password: 'baggins'
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid credentials"
    assert_nil session[:credentials]
  end

  def test_sign_out
    get '/', {}, {"rack.session" => { credentials: { username: 'admin', password: 'secret'} } }
    refute_nil session[:credentials]
    post '/sign_out'
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "You have been signed out."
    assert_nil session[:credentials]
  end
end
