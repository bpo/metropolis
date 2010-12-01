# -*- encoding: binary -*-

require 'tdb'

module Metropolis::TDB
  include Metropolis::Common

  def setup(opts)
    super
    path_pattern = opts[:path_pattern]
    path_pattern.scan(/%\d*x/).size == 1 or
      raise ArgumentError, "only one '/%\d*x/' may appear in #{path_pattern}"
    @tdb_opts = { :tdb_flags => 0 }
    if @readonly
      @tdb_opts[:open_flags] = IO::RDONLY
      extend Metropolis::Common::RO
    end
    if query = opts[:query]
      size = query['hash_size'] and @tdb_opts[:hash_size] = size.to_i
      hash = query['hash'] and @tdb_opts[:hash] = hash.to_sym

      case query['volatile']
      when 'true'; @tdb_opts[:tdb_flags] |= TDB::VOLATILE
      when 'false', nil
      else
        raise ArgumentError, "'volatile' must be 'true' or 'false'"
      end

      case query['sync']
      when 'true', nil
      when 'false'; @tdb_opts[:tdb_flags] |= TDB::NOSYNC
      else
        raise ArgumentError, "'sync' must be 'true' or 'false'"
      end
    end

    @dbv = (0...@nr_slots).to_a.map do |slot|
      path = sprintf(path_pattern, slot)
      ::TDB.new(path, @tdb_opts)
    end
  end

  def db(key, &block)
    yield @dbv[key.hash % @nr_slots]
  end

  def put(key, env)
    value = env["rack.input"].read
    db(key) do |tdb|
      case env['HTTP_X_TT_PDMODE']
      when '1'
        # TODO: make this atomic
        return r(409) if tdb.include?(key)
      when '2'
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
    value = db(key) { |tdb| tdb.fetch(key) } or return r(404)
    [ 200, { 'Content-Length' => value.size.to_s }.merge!(@headers), [ value ] ]
  end

  def close!
    @dbv.each { |tdb| tdb.close }
  end
end
