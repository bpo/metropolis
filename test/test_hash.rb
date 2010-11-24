# -*- encoding: binary -*-
require './test/rack_read_write.rb'
$-w = true
require 'metropolis'

class Test_Hash < Test::Unit::TestCase
  attr_reader :tmp, :o, :uri
  include TestRackReadWrite

  def setup
    @tmp = Tempfile.new('hash')
    File.unlink(@tmp)
    @uri = "hash://#{@tmp.path}"
  end

  def teardown
    @tmp.close!
  end

  def test_marshalled
    File.open(@tmp, "wb") { |fp| fp.write(Marshal.dump({"x" => "y"})) }
    app = Metropolis.new(:uri => @uri, :readonly => true)
    o = { :lint => true, :fatal => true }
    req = Rack::MockRequest.new(app)

    r = req.put("/x", o.merge(:input=>"ASDF"))
    assert_equal 403, r.status

    r = req.get("/x")
    assert_equal 200, r.status
    assert_equal "y", r.body

    r = req.request("HEAD", "/x", {})
    assert_equal 200, r.status
    assert_equal "", r.body

    r = req.delete("/x", {})
    assert_equal 403, r.status
  end
end
