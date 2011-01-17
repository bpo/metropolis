# -*- encoding: binary -*-
require "zlib"

# allows storing pre-gzipped data on disk and serving it
# as-is for clients that accept that gzip encoding
module Metropolis::Gzip
  include Metropolis::Constants
  Compression = "gzip"

  def get(key, env)
    status, headers, body = r = super
    if 200 == status && /\bgzip\b/ !~ env[HTTP_ACCEPT_ENCODING]
      body[0] = Zlib::GzipReader.new(StringIO.new(body[0])).read
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
      zipped = StringIO.new("")
      Zlib::GzipWriter.wrap(zipped) { |io| io.write(@input.read) }
      zipped.string
    end
  end
end
