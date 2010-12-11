# -*- encoding: binary -*-
module Metropolis::MultiHash
  autoload :Digest, 'metropolis/multi_hash/digest'
  autoload :ToI, 'metropolis/multi_hash/to_i'

  def self.extended(obj)
    sym = obj.instance_eval {
      case @multi_hash.to_s
      when /\Ato_i/
        extend Metropolis::MultiHash::ToI
      when /\Adigest_/
        extend Metropolis::MultiHash::Digest
      when /\Atdb_hash_/
        extend TDB::HashFunctions
      end
      @multi_hash
    }
    obj.respond_to?(sym) or
      raise ArgumentError, "multi_hash=#{sym} not supported"
    (class << obj; self; end).instance_eval do
      alias_method :multi_hash, sym
    end
  end
end
