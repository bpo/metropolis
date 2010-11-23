# -*- encoding: binary -*-
require 'rack'
require 'uri'

module Metropolis
  autoload :TC, 'metropolis/tc'

  def self.new(opts = {})
    opts = opts.dup
    rv = Object.new
    uri = URI.parse(opts[:uri])
    case uri.scheme
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
