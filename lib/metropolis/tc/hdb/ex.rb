module Metropolis::TC::HDB::EX
  def self.extended(obj)
   obj.instance_eval do
      @wr_flags |= @rd_flags
      @rd_flags = nil
      @dbv.each { |(hdb, path)|
        hdb.open(path, @wr_flags) or ex!(:open, hdb)
      }
      @ex_dbv = @dbv.map { |(hdb,_)| hdb }
    end
  end

  def reader(key)
    yield @ex_dbv[multi_hash(key) % @nr_slots]
  end

  alias_method :writer, :reader
end
