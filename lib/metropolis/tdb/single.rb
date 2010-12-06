# -*- encoding: binary -*-
module Metropolis::TDB::Single
  def self.extended(obj)
    obj.instance_eval do
      @db = ::TDB.new(@uri.path, @tdb_opts)
    end
  end

  def db(key, &block)
    yield @db
  end

  def close!
    @db.close
  end
end
