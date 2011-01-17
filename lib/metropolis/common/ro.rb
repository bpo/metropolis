# -*- encoding: binary -*-
module Metropolis::Common::RO
  include Metropolis::Constants

  def call(env)
    if %r{\A/(.*)\z} =~ env[PATH_INFO]
      key = unescape($1)
      case env[REQUEST_METHOD]
      when "GET"
        get(key, env)
      when "HEAD"
        head(key, env)
      else
        r(403)
      end
    else # OPTIONS
      r(405)
    end
  end
end
