ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require 'minitest/reporters'
require "rack/test"
Minitest::Reporters.use!

require_relative '../cms'

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup

  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "history.txt"
    assert_includes last_response.body, "changes.txt"
  end

  def test_history
    response_body = "1993 - Yukihiro Matsumoto dreams up Ruby.\n1995 - Ruby 0.95 released.\n1996 - Ruby 1.0 released.\n1998 - Ruby 1.2 released.\n1999 - Ruby 1.4 released.\n2000 - Ruby 1.6 released.\n2003 - Ruby 1.8 released.\n2007 - Ruby 1.9 released.\n2013 - Ruby 2.0 released.\n2013 - Ruby 2.1 released.\n2014 - Ruby 2.2 released.\n2015 - Ruby 2.3 released.\n2016 - Ruby 2.4 released.\n2017 - Ruby 2.5 released.\n2018 - Ruby 2.6 released.\n2019 - Ruby 2.7 released.\n"

    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain;charset=utf-8", last_response["Content-Type"]
    assert_equal response_body, last_response.body
  end

  def test_bad_path
    get "/nofile.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "nofile.txt does not exist."

    get "/"
    refute_includes last_response.body, "nofile.txt does not exist."
  end

  def text_markdown
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end
end
