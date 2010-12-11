# -*- encoding: binary -*-

module Metropolis::TC::HDB::RO
  include Metropolis::Common::RO

  def self.extended(obj)
   obj.instance_eval do
      @wr_flags = nil
      @dbv.each { |(hdb, path)|
        hdb.open(path, @rd_flags) or ex!(:open, hdb)
      }
      @ro_dbv = @dbv.map { |(hdb,_)| hdb }
    end
  end

  def reader(key)
    yield @ro_dbv[multi_hash(key) % @nr_slots]
  end
end
