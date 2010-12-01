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
    @uri = "tdb://#{@path_pattern}"
  end

  def teardown
    Dir[@path_pattern.sub!(/%\d*x/, '*')].each { |x| File.unlink(x) }
  end
end
