# -*- encoding: binary -*-
require "zlib"

# allows storing pre-deflated data on disk and serving it
# as-is for clients that accept that deflate encoding
module Metropolis::Deflate
  include Metropolis::Constants
  Compression = "deflate"

  def get(key, env)
    status, headers, body = r = super
    if 200 == status && /\bdeflate\b/ !~ env[HTTP_ACCEPT_ENCODING]
      inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
      body[0] = inflater.inflate(body[0]) << inflater.finish
      inflater.end
      headers[Content_Length] = body[0].size.to_s
      headers.delete(Content_Encoding)
      headers.delete(Vary)
    end
    r
  end

  def put(key, env)
    Wrapper.new(env) if Compression != env[HTTP_CONTENT_ENCODING]
    super(key, env)
  end

  def self.extended(obj)
    obj.instance_eval do
      @headers[Content_Encoding] = Compression
      @headers[Vary] = Accept_Encoding
    end
  end

  class Wrapper < Metropolis::InputWrapper

    def read_all
      deflater = Zlib::Deflate.new(
        Zlib::DEFAULT_COMPRESSION,
        # drop the zlib header which causes both Safari and IE to choke
        -Zlib::MAX_WBITS,
        Zlib::DEF_MEM_LEVEL,
        Zlib::DEFAULT_STRATEGY
      )
      deflater.deflate(@input.read) << deflater.finish
    end
  end
end
