# -*- encoding: binary -*-
require 'rack'
require 'uri'

module Metropolis
  autoload :InputWrapper, 'metropolis/input_wrapper'
  autoload :Deflate, 'metropolis/deflate'
  autoload :Gzip, 'metropolis/gzip'
  autoload :TC, 'metropolis/tc'
  autoload :Hash, 'metropolis/hash'
  autoload :TDB, 'metropolis/tdb'
  autoload :MultiHash, 'metropolis/multi_hash'

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

require 'metropolis/common'
