# -*- encoding: binary -*-
require './test/rack_read_write.rb'
require 'tokyocabinet' # FIXME: emits warning with 1.29 gem
$-w = true
require 'metropolis'

class Test_TC_HDB < Test::Unit::TestCase
  attr_reader :tmp, :o, :uri
  include TestRackReadWrite

  def setup
    tmp = Tempfile.new('tchdb')
    @path_pattern = tmp.path + ".%01x.tch"
    tmp.close!
    @uri = "tc://#{@path_pattern}"
  end

  def teardown
    Dir[@path_pattern.sub!(/%\d*x/, '*')].each { |x| File.unlink(x) }
  end

  def osetup
    o = Object.new
    o.extend Metropolis::TC::HDB
    assert_nothing_raised do
      o.setup :path_pattern => @path_pattern
    end
    o
  end

  def test_create_put_get_delete
    o = osetup
    r = o.put('hello', { 'rack.input' => StringIO.new('world') })
    assert_equal 201, r[0].to_i
    assert_equal 'text/plain', r[1]['Content-Type']
    assert_equal '8', r[1]['Content-Length']
    assert_equal "Created\n", r[2].join('')

    r = o.put('hellox', { 'rack.input' => StringIO.new('worldx') })
    assert_equal 201, r[0].to_i
    assert_equal 'text/plain', r[1]['Content-Type']
    assert_equal '8', r[1]['Content-Length']
    assert_equal "Created\n", r[2].join('')

    r = o.get('hello')
    assert_equal 200, r[0].to_i
    assert_equal 'application/octet-stream', r[1]['Content-Type']
    assert_equal '5', r[1]['Content-Length']
    assert_equal %w(world), r[2]

    r = o.head('hello')
    assert_equal 200, r[0].to_i
    assert_equal 'application/octet-stream', r[1]['Content-Type']
    assert_equal '5', r[1]['Content-Length']
    assert_equal [], r[2]

    r = o.get('hellox')
    assert_equal 200, r[0].to_i
    assert_equal 'application/octet-stream', r[1]['Content-Type']
    assert_equal '6', r[1]['Content-Length']
    assert_equal %w(worldx), r[2]

    r = o.delete('hellox')
    assert_equal 200, r[0].to_i
    assert_equal 'text/plain', r[1]['Content-Type']
    assert_equal '3', r[1]['Content-Length']
    assert_equal "OK\n", r[2].join('')

    r = o.delete('hellox')
    assert_equal 404, r[0].to_i
    assert_equal 'text/plain', r[1]['Content-Type']
    assert_equal '10', r[1]['Content-Length']
    assert_equal "Not Found\n", r[2].join('')

    r = o.get('hellox')
    assert_equal 404, r[0].to_i
    assert_equal 'text/plain', r[1]['Content-Type']
    assert_equal '10', r[1]['Content-Length']
    assert_equal "Not Found\n", r[2].join('')

    r = o.head('hellox')
    assert_equal 404, r[0].to_i
    assert_equal 'text/plain', r[1]['Content-Type']
    assert_equal '0', r[1]['Content-Length']
    assert_equal "", r[2].join('')
  end

  def test_putkeep
    o = osetup
    env = {
      "rack.input" => StringIO.new("hello"),
      "HTTP_X_TT_PDMODE" => "1"
    }
    assert_equal 201, o.put("x", env)[0]
    env["rack.input"] = StringIO.new("wrong")
    assert_equal 409, o.put("x", env)[0]
    assert_equal "hello", o.get("x")[2].join('')
  end

  def test_putcat
    o = osetup
    env = {
      "rack.input" => StringIO.new("hello"),
      "HTTP_X_TT_PDMODE" => "2"
    }
    assert_equal 201, o.put("x", env)[0]
    env["rack.input"] = StringIO.new("MOAR")
    assert_equal 201, o.put("x", env)[0]
    assert_equal "helloMOAR", o.get("x")[2].join('')
  end

  def test_multiproc
    nr = 2
    key = "k"
    str = "." * (1024 * 1024)
    nr.times {
      fork {
        o = osetup
        sio = StringIO.new(str)
        env = { "rack.input" => sio }
        100.times {
          o.put(key, env)
          sio.rewind
          o.get(key)
        }
      }
    }
    res = Process.waitall
    assert_equal nr, res.size
    res.each { |(pid, status)| assert status.success? }
  end if ENV["TEST_EXPENSIVE"]

  def test_readonly
    key = "x"
    wr = osetup
    wr.put(key, { "rack.input" => StringIO.new("OK") })
    o = Object.new
    o.extend Metropolis::TC::HDB
    assert_nothing_raised do
      o.setup :path_pattern => @path_pattern, :readonly => true
    end
    %w(PUT DELETE).each do |rm|
      env = {
        "rack.input" => StringIO.new("FAIL"),
        "REQUEST_METHOD" => rm,
        "PATH_INFO" => "/#{key}"
      }
      assert_equal 403, o.call(env)[0]
    end
    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/#{key}",
    }
    assert_equal 200, o.call(env)[0]
    assert_equal '2', o.call(env)[1]["Content-Length"]
    assert_equal 'application/octet-stream', o.call(env)[1]["Content-Type"]
    assert_equal "OK", o.call(env)[2].join('')

    env["REQUEST_METHOD"] = "HEAD"
    assert_equal 200, o.call(env)[0]
    assert_equal '2', o.call(env)[1]["Content-Length"]
    assert_equal 'application/octet-stream', o.call(env)[1]["Content-Type"]
    assert_equal "", o.call(env)[2].join('')
  end

  def test_create_toplevel
    k = "x"
    nr_bytes = 1024 * 1024 * 20
    data = "0" * nr_bytes
    obj = nil
    assert_nothing_raised { obj = Metropolis.new(:uri => uri) }

    query = "large=true&apow=3&bnum=65536&compress=deflate"
    assert_nothing_raised {
      obj = Metropolis.new(:uri => "#{uri}?#{query}")
    }
    optimize_args = obj.instance_variable_get(:@optimize)
    flags = TokyoCabinet::HDB::TLARGE | TokyoCabinet::HDB::TDEFLATE
    assert_equal flags, optimize_args[3]
    assert_equal 65536, optimize_args[0]
    assert_nil optimize_args[2]
    assert_equal 3, optimize_args[1]
    assert_nothing_raised { obj.get(k) }
    assert_nothing_raised { obj.put(k,{'rack.input' => StringIO.new(data)}) }

    obj = Metropolis.new(:uri => "#{uri}?#{query}", :readonly => true)
    assert_equal data, obj.get(k)[2].join('')
    obj.close!

    obj = Metropolis.new(:uri => uri, :readonly => true)
    assert_equal data, obj.get(k)[2].join('')
    obj.close!
    sum = obj.instance_eval {
      @dbv.inject(0) { |size, (hdb,path)| size += File.stat(path).size }
    }
    assert sum <= nr_bytes, "#{sum} > #{nr_bytes}"
    obj.close!
  end
end
