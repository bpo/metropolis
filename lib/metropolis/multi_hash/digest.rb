# -*- encoding: binary -*-
require 'digest'
module Metropolis::MultiHash::Digest
  def digest_sha1(key)
    ::Digest::SHA1.digest(key)[0,4].unpack("N")[0]
  end

  def digest_md5(key)
    ::Digest::MD5.digest(key)[0,4].unpack("N")[0]
  end

  def digest_sha256(key)
    ::Digest::SHA256.digest(key)[0,4].unpack("N")[0]
  end

  def digest_sha384(key)
    ::Digest::SHA384.digest(key)[0,4].unpack("N")[0]
  end

  def digest_sha512(key)
    ::Digest::SHA512.digest(key)[0,4].unpack("N")[0]
  end
end
