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
    response_body = "<!DOCTYPE html>\n<html lang=\"en\" dir=\"ltr\">\n<head>\n  <meta charset=\"utf-8\" />\n  <title>CMS</title>\n</head>\n<body>\n  <ul>\n  <li><a href=\"/data/changes.txt\">changes.txt</a></li>\n  <li><a href=\"/data/about.txt\">about.txt</a></li>\n  <li><a href=\"/data/history.txt\">history.txt</a></li>\n</ul>\n\n</body>\n</html>\n"

    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal response_body, last_response.body
  end

  def test_history
    response_body = "1993 - Yukihiro Matsumoto dreams up Ruby.\n1995 - Ruby 0.95 released.\n1996 - Ruby 1.0 released.\n1998 - Ruby 1.2 released.\n1999 - Ruby 1.4 released.\n2000 - Ruby 1.6 released.\n2003 - Ruby 1.8 released.\n2007 - Ruby 1.9 released.\n2013 - Ruby 2.0 released.\n2013 - Ruby 2.1 released.\n2014 - Ruby 2.2 released.\n2015 - Ruby 2.3 released.\n2016 - Ruby 2.4 released.\n2017 - Ruby 2.5 released.\n2018 - Ruby 2.6 released.\n2019 - Ruby 2.7 released.\n"

    get "/data/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain;charset=utf-8", last_response["Content-Type"]
    assert_equal response_body, last_response.body
  end
end
