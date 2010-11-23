# -*- encoding: binary -*-
require 'test/unit'
require 'stringio'
require 'tempfile'
require 'rack'

module TestRackReadWrite
  def test_rack_read_write
    app = Metropolis.new(:uri => uri)
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
    app = Metropolis.new(:uri => uri, :readonly => true)
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
