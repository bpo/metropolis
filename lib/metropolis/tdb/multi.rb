# -*- encoding: binary -*-
module Metropolis::TDB::Multi
  def self.extended(obj)
    obj.instance_eval do
      @dbv = (0...@nr_slots).to_a.map do |slot|
        path = sprintf(@path_pattern, slot)
        ::TDB.new(path, @tdb_opts)
      end
    end
  end

  def db(key, &block)
    yield @dbv[key.hash % @nr_slots]
  end

  def close!
    @dbv.each { |tdb| tdb.close }
  end
end
