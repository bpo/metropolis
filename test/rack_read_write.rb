# -*- encoding: binary -*-
require 'test/unit'
require 'stringio'
require 'tempfile'
require 'rack'

module TestRackReadWrite
  attr_reader :app

  def test_rack_read_write_deflated
    @app = Metropolis.new(:uri => uri, :encoding => :deflate)
    basic_rest

    blob = "." * 1024 * 1024
    o = { :lint => true, :fatal => true }
    req = Rack::MockRequest.new(app)

    r = req.put("/asdf", o.merge(:input => blob))
    assert_equal 201, r.status
    assert_equal "Created\n", r.body

    r = req.get("/asdf", o.merge("HTTP_ACCEPT_ENCODING" => "deflate"))
    assert_equal 200, r.status
    assert_equal "deflate", r.headers['Content-Encoding']
    assert r.body.size < blob.size

    r = req.get("/asdf", o.merge("HTTP_ACCEPT_ENCODING" => "gzip"))
    assert_equal 200, r.status
    assert_nil r.headers['Content-Encoding']
    assert_equal blob, r.body
  end

  def test_rack_read_write_gzipped
    @app = Metropolis.new(:uri => uri, :encoding => :gzip)
    basic_rest

    blob = "." * 1024 * 1024
    o = { :lint => true, :fatal => true }
    req = Rack::MockRequest.new(app)

    r = req.put("/asdf", o.merge(:input => blob))
    assert_equal 201, r.status
    assert_equal "Created\n", r.body

    r = req.get("/asdf", o.merge("HTTP_ACCEPT_ENCODING" => "gzip"))
    assert_equal 200, r.status
    assert_equal "gzip", r.headers['Content-Encoding']
    assert r.body.size < blob.size

    r = req.get("/asdf", o.merge("HTTP_ACCEPT_ENCODING" => "deflate"))
    assert_equal 200, r.status
    assert_nil r.headers['Content-Encoding']
    assert_equal blob, r.body
  end

  def test_rack_read_write
    @app = Metropolis.new(:uri => uri)
    basic_rest
  end

  def basic_rest
    o = { :lint => true, :fatal => true }
    req = Rack::MockRequest.new(app)

    r = req.put("/asdf", o.merge(:input=>"ASDF"))
    assert_equal 201, r.status
    assert_equal "Created\n", r.body

    r = req.get("/asdf")
    assert_equal 200, r.status
    assert_equal "ASDF", r.body

    r = req.request("HEAD", "/asdf", {})
    assert_equal 200, r.status
    assert_equal "", r.body

    r = req.delete("/asdf", {})
    assert_equal 200, r.status
    assert_equal "OK\n", r.body

    r = req.get("/asdf")
    assert_equal 404, r.status
    assert_equal "Not Found\n", r.body

    r = req.delete("/asdf", {})
    assert_equal 404, r.status
    assert_equal "Not Found\n", r.body

    r = req.request("HEAD", "/asdf", {})
    assert_equal 404, r.status
    assert_equal "", r.body
  end

  def test_rack_readonly
    tmp = Metropolis.new(:uri => uri)
    tmp.close!
    @app = Metropolis.new(:uri => uri, :readonly => true)
    basic_rest_readonly
  end

  def basic_rest_readonly
    o = { :lint => true, :fatal => true }
    req = Rack::MockRequest.new(app)

    r = req.put("/asdf", o.merge(:input=>"ASDF"))
    assert_equal 403, r.status

    r = req.get("/asdf")
    assert_equal 404, r.status

    r = req.request("HEAD", "/asdf", {})
    assert_equal 404, r.status

    r = req.delete("/asdf", {})
    assert_equal 403, r.status
  end
end
