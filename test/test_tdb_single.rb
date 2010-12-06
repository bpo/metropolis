# -*- encoding: binary -*-
require './test/rack_read_write.rb'
$-w = true
require 'metropolis'

class Test_TDB_Single < Test::Unit::TestCase
  attr_reader :tmp, :o, :uri
  include TestRackReadWrite

  def setup
    @tmp = Tempfile.new('tdb')
    @path = @tmp.path + '.tdb'
    @uri = "tdb://#{@path}"
    @app_opts = { :uri => @uri }
  end

  def teardown
    @tmp.close!
    File.unlink(@path)
  end
end
