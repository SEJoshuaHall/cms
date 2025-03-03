ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_response.body, "about.txt")
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "history.txt")
  end

  def test_file_display
    get "/about.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes(last_response.body, "ipsum")
  end

  def test_invalid_path
    get "/notafile.ext"

    assert_includes(last_response.status.to_s, '30')
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "notafile.ext does not exist"

    get "/"
    refute_includes last_response.body, "notafile.ext does not exist"
  end

  def test_viewing_markdown_document
    get "/test.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "here be dragons"
  end

  def test_edit
    get "/about.txt/edit"

    assert_equal 200, last_response.status 
  end

end