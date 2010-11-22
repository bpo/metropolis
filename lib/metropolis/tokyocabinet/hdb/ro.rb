# -*- encoding: binary -*-

module Metropolis::TokyoCabinet::HDB::RO
  def self.extended(obj)
   obj.instance_eval do
      @wr_flags = nil
      @rd_flags |= ::TokyoCabinet::HDB::ONOLCK
      @hdbv.each { |(hdb, path)|
        hdb.open(path, @rd_flags) or ex!(:open, path)
      }
      @ro_hdbv = @hdbv.map { |(hdb,_)| hdb }
    end
  end

  def call(env)
    if %r{\A/(.*)\z} =~ env["PATH_INFO"]
      key = unescape($1)
      case env["REQUEST_METHOD"]
      when "GET"
        get(key)
      when "HEAD"
        head(key)
      else
        [ 405, {}, [] ]
      end
    else # OPTIONS
      [ 405, {}, [] ]
    end
  end

  def reader(key)
    yield @ro_hdbv[key.hash % @nr_slots]
  end
end
