# -*- encoding: binary -*-

# this module is NOT thread-safe, all performance is dependent on the
# local machine so there is never anything that needs yielding to threads.
module Metropolis::TC::HDB
  autoload :RO, 'metropolis/tc/hdb/ro'

  TCHDB = TokyoCabinet::HDB # :nodoc
  include Metropolis::Common

  def setup(opts)
    @headers = { 'Content-Type' => 'application/octet-stream' }
    @headers.merge!(opts[:response_headers] || {})
    @nr_slots = opts[:nr_slots] || 3
    path_pattern = opts[:path_pattern]
    path_pattern.scan(/%\d*x/).size == 1 or
      raise ArgumentError, "only one '/%\d*x/' may appear in #{path_pattern}"
    @optimize = nil
    if query = opts[:query]
      flags = 0
      @optimize = %w(bnum apow fpow).map do |x|
        v = query[x]
        v ? v.to_i : nil
      end
      case large = query['large']
      when 'false', nil
      when 'true'
        flags |= TCHDB::TLARGE
      else
        raise ArgumentError, "invalid 'large' value: #{large}"
      end
      case compress = query['compress']
      when nil
      when 'deflate', 'bzip', 'tcbs'
        flags |= TCHDB.const_get("T#{compress.upcase}")
      else
        raise ArgumentError, "invalid 'compress' value: #{compress}"
      end
      @optimize << flags
    end
    @dbv = (0...@nr_slots).to_a.map do |slot|
      path = sprintf(path_pattern, slot)
      hdb = TCHDB.new
      unless opts[:read_only]
        hdb.open(path, TCHDB::OWRITER | TCHDB::OCREAT) or ex!(:open, hdb)
        if @optimize
          hdb.optimize(*@optimize) or ex!(:optimize, hdb)
        end
        hdb.close or ex!(:close, hdb)
      end
      [ hdb, path ]
    end
    @rd_flags = TCHDB::OREADER
    @wr_flags = TCHDB::OWRITER
    if opts[:read_only]
      extend(RO)
    end
  end


  def ex!(msg, hdb)
    raise "#{msg}: #{hdb.errmsg(hdb.ecode)}"
  end

  def writer(key, &block)
    hdb, path = @dbv[key.hash % @nr_slots]
    hdb.open(path, @wr_flags) or ex!(:open, hdb)
    yield hdb
    ensure
      hdb.close or ex!(:close, hdb)
  end

  def reader(key)
    hdb, path = @dbv[key.hash % @nr_slots]
    hdb.open(path, @rd_flags) or ex!(:open, hdb)
    yield hdb
    ensure
      hdb.close or ex!(:close, hdb)
  end

  def put(key, env)
    value = env["rack.input"].read
    writer(key) do |hdb|
      case env['HTTP_X_TT_PDMODE']
      when '1'
        unless hdb.putkeep(key, value)
          TCHDB::EKEEP == hdb.ecode and return r(409)
          ex!(:putkeep, hdb)
        end
      when '2'
        hdb.putcat(key, value) or ex!(:putcat, hdb)
      else
        # ttserver does not care for other PDMODE values, so we don't, either
        hdb.put(key, value) or ex!(:put, hdb)
      end
    end
    r(201)
  end

  def delete(key)
    writer(key) do |hdb|
      unless hdb.delete(key)
        TCHDB::ENOREC == hdb.ecode and return r(404)
        ex!(:delete, hdb)
      end
    end
    r(200)
  end

  def head(key)
    size = reader(key) { |hdb| hdb.vsiz(key) or ex!(:vsiz, hdb) }
    0 > size and return r(404)
    [ 200, { 'Content-Length' => size.to_s }.merge!(@headers), [] ]
  end

  def get(key)
    value = nil
    reader(key) do |hdb|
      unless value = hdb.get(key)
        TCHDB::ENOREC == hdb.ecode and return r(404)
        ex!(:get, hdb)
      end
    end
    [ 200, { 'Content-Length' => value.size.to_s }.merge!(@headers), [ value ] ]
  end

  def close!
    @dbv.each { |(hdb,_)| hdb.close }
  end
end
