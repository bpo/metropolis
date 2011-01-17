# -*- encoding: binary -*-
require 'rack'
require 'uri'

# Metropolis is configured using Rack::Builder, so "run" it like
# any other Rack application by placing it in your config.ru:
#
#     run Metropolis.new(:uri => "hash:///")
module Metropolis
  autoload :InputWrapper, 'metropolis/input_wrapper'
  autoload :Deflate, 'metropolis/deflate'
  autoload :Gzip, 'metropolis/gzip'
  autoload :TC, 'metropolis/tc'
  autoload :Hash, 'metropolis/hash'
  autoload :TDB, 'metropolis/tdb'
  autoload :MultiHash, 'metropolis/multi_hash'
  autoload :SuffixMime, 'metropolis/suffix_mime'

  def self.new(opts = {})
    opts = opts.dup
    rv = Object.new
    uri = URI.parse(opts[:uri])
    rv.instance_eval do
      @uri = uri
      @query = @uri.query ? Rack::Utils.parse_query(@uri.query) : nil
      @path_pattern = opts[:path_pattern]
      @path = @uri.path if @uri.path != '/'
      @multi_hash = opts[:multi_hash]
    end

    base = case uri.scheme
    when 'hash' then Metropolis::Hash
    when 'tdb' then Metropolis::TDB
    when 'tc' then Metropolis::TC
    else
      raise ArgumentError, "unsupported URI scheme: #{uri.scheme}"
    end
    rv.extend(base)
    rv.setup(opts)
    rv
  end
end

require 'metropolis/constants'
require 'metropolis/common'
