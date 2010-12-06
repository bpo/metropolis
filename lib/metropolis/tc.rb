# -*- encoding: binary -*-
require 'tokyocabinet'

module Metropolis::TC
  autoload :HDB, 'metropolis/tc/hdb'

  def self.extended(obj)
    obj.instance_eval do
      case ext = File.extname(@path_pattern || @path)
      when '.tch'
        extend Metropolis::TC::HDB
      else
        raise ArgumentError, "unsupported suffix: #{ext}"
      end
    end
  end
end
