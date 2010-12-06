# -*- encoding: binary -*-
require './test/rack_read_write.rb'
require 'tokyocabinet' # FIXME: emits warning with 1.29 gem
$-w = true
require 'metropolis'

class Test_TC_HDB_Single < Test::Unit::TestCase
  attr_reader :tmp, :o, :uri
  include TestRackReadWrite

  def setup
    @tmp = Tempfile.new('tchdb')
    @path = @tmp.path + '.tch'
    @uri = "tc://#{@path}"
    @app_opts = { :uri => @uri }
  end

  def teardown
    @tmp.close!
    File.unlink(@path)
  end
end
