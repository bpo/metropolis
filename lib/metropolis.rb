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

  def self.new(opts = {})
    opts = opts.dup
    rv = Object.new
    uri = opts[:uri] = URI.parse(opts[:uri])
    if uri.path != '/' && opts[:path_pattern]
      raise ArgumentError, ":path_pattern may only be used if path is '/'"
    end
    case uri.scheme
    when 'hash'
      opts[:path] = uri.path if uri.path != '/'
      rv.extend Metropolis::Hash
    when 'tdb'
      opts[:query] = Rack::Utils.parse_query(uri.query) if uri.query
      rv.extend Metropolis::TDB
    when 'tc'
      opts[:query] = Rack::Utils.parse_query(uri.query) if uri.query
      case ext = File.extname(opts[:path_pattern] || uri.path)
      when '.tch'
        rv.extend Metropolis::TC::HDB
      else
        raise ArgumentError, "unsupported suffix: #{ext}"
      end
    else
      raise ArgumentError, "unsupported URI scheme: #{uri.scheme}"
    end
    rv.setup(opts)
    rv
  end
end

require 'metropolis/common'
