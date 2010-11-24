# -*- encoding: binary -*-
require 'tempfile'

# use a Ruby hash as a plain data store
# It can unmarshal a hash from disk
module Metropolis::Hash
  include Metropolis::Common

  def setup(opts)
    super
    if @path = opts[:path]
      begin
        @db = Marshal.load(File.open(@path, "rb") { |fp| fp.read })
        Hash === @db or raise ArgumentError, "#@path is not a marshaled Hash"
      rescue Errno::ENOENT
        @db = {}
      end
    else
      @db = {}
    end
    if @readonly
      extend Metropolis::Common::RO
    else
      args = [ @db, @path, !!opts[:fsync] ]
      @clean_proc = Metropolis::Hash.finalizer_callback(args)
      ObjectSpace.define_finalizer(self, @clean_proc)
    end
  end

  def close!
    unless @readonly
      @clean_proc.call
      ObjectSpace.undefine_finalizer(self)
    end
    @db = @path = nil
  end

  def get(key)
    value = @db[key] or return r(404)
    [ 200, { 'Content-Length' => value.size.to_s }.merge!(@headers), [ value ] ]
  end

  def put(key, env)
    value = env["rack.input"].read
    case env['HTTP_X_TT_PDMODE']
    when '1'
      @db.exists?(key) and r(409)
      @db[key] = value
    when '2'
      (tmp = @db[key] ||= "") << value
    else
      @db[key] = value
    end
    r(201)
  end

  def delete(key)
    r(@db.delete(key) ? 200 : 404)
  end

  def self.finalizer_callback(data)
    lambda {
      db, path, fsync = data
      dir = File.dirname(path)
      tmp = Tempfile.new('hash_save', dir)
      tmp.binmode
      tmp.sync = true
      tmp.write(Marshal.dump(db))
      tmp.fsync if fsync
      File.rename(tmp.path, path)
      File.open(dir) { |d| d.fsync } if fsync
      tmp.close!
    }
  end
end
