# -*- encoding: binary -*-

require 'tdb'

module Metropolis::TDB
  include Metropolis::Common
  autoload :Single, 'metropolis/tdb/single'
  autoload :Multi, 'metropolis/tdb/multi'

  def setup(opts)
    super
    @rbuf = ""
    @tdb_opts = { :tdb_flags => 0 }
    if @readonly
      @tdb_opts[:open_flags] = IO::RDONLY
      extend Metropolis::Common::RO
    end
    if @query
      size = @query['hash_size'] and @tdb_opts[:hash_size] = size.to_i
      hash = @query['hash'] and @tdb_opts[:hash] = hash.to_sym

      case @query['threadsafe']
      when 'true'; @tdb_opts[:threadsafe] = true
      when 'false', nil
      else
        raise ArgumentError, "'threadsafe' must be 'true' or 'false'"
      end

      case @query['volatile']
      when 'true'; @tdb_opts[:tdb_flags] |= TDB::VOLATILE
      when 'false', nil
      else
        raise ArgumentError, "'volatile' must be 'true' or 'false'"
      end

      case @query['sync']
      when 'true', nil
      when 'false'; @tdb_opts[:tdb_flags] |= TDB::NOSYNC
      else
        raise ArgumentError, "'sync' must be 'true' or 'false'"
      end
    end
    extend(@path_pattern ? Metropolis::TDB::Multi : Metropolis::TDB::Single)
  end

  def put(key, env)
    value = env[Rack_Input].read
    db(key) do |tdb|
      case env[HTTP_X_TT_PDMODE]
      when "1"
        # TODO: make this atomic
        return r(409) if tdb.include?(key)
      when "2"
        value = (tdb.get(key) || "") << value
      end
      tdb.store(key, value)
    end
    r(201)
  end

  def delete(key)
    r(db(key) { |tdb| tdb.nuke!(key) } ? 200 : 404)
  end

  def get(key, env)
    value = db(key) { |tdb| tdb.fetch(key, @rbuf) } or return r(404)
    [ 200, { Content_Length => value.size.to_s }.merge!(@headers), [ value ] ]
  end
end
