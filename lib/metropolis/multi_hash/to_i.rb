# -*- encoding: binary -*-
# simple "hashing" method which converts keys to integers,
# this may be useful for databases that only store numeric keys
module Metropolis::MultiHash::ToI
  def to_i(key)
    key.to_i
  end

  def to_i_16(key)
    key.to_i(16)
  end
end
