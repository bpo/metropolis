# -*- encoding: binary -*-
require 'rack'
require 'uri'

module Metropolis
  autoload :InputWrapper, 'metropolis/input_wrapper'
  autoload :Deflate, 'metropolis/deflate'
  autoload :Gzip, 'metropolis/gzip'
  autoload :TC, 'metropolis/tc'
  autoload :Hash, 'metropolis/hash'

  def self.new(opts = {})
    opts = opts.dup
    rv = Object.new
    uri = opts[:uri] = URI.parse(opts[:uri])
    case uri.scheme
    when 'hash'
      opts[:path] = uri.path if uri.path != '/'
      rv.extend Metropolis::Hash
    when 'tc'
      opts[:path_pattern] = uri.path
      opts[:query] = Rack::Utils.parse_query(uri.query) if uri.query
      case ext = File.extname(uri.path)
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
