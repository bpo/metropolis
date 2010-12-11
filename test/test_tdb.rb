# -*- encoding: binary -*-
require './test/rack_read_write.rb'
$-w = true
require 'metropolis'

class Test_TDB < Test::Unit::TestCase
  attr_reader :tmp, :o, :uri
  include TestRackReadWrite

  def setup
    tmp = Tempfile.new('tdb')
    @path_pattern = tmp.path + ".%01x.tdb"
    tmp.close!
    @uri = "tdb:///"
    @app_opts = { :uri => @uri, :path_pattern => @path_pattern }
  end

  def test_alternate_hash
    n = 7
    @app = Metropolis.new(@app_opts.merge(:nr_slots => n, :multi_hash => :to_i))
    req = Rack::MockRequest.new(app)
    o = { :lint => true, :fatal => true, :input => "." }
    (1..8).each do |i|
      r = req.put("/#{i * n}", o)
      assert_equal 201, r.status
      assert_equal "Created\n", r.body
    end
    tmp = Hash.new { |h,k| h[k] = {} }
    @app.instance_eval do
      @dbv.each_with_index { |db,i| db.each { |k,v| tmp[i][k] = v } }
    end
    expect = {
      0 => {
        "7" => ".",
        "14" => ".",
        "21" => ".",
        "28" => ".",
        "35" => ".",
        "42" => ".",
        "49" => ".",
        "56" => ".",
      }
    }
    assert_equal expect, tmp
  end

  def teardown
    Dir[@path_pattern.sub!(/%\d*x/, '*')].each { |x| File.unlink(x) }
  end
end
