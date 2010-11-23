# -*- encoding: binary -*-
module Metropolis::Common::RO
  def call(env)
    if %r{\A/(.*)\z} =~ env["PATH_INFO"]
      key = unescape($1)
      case env["REQUEST_METHOD"]
      when "GET"
        get(key)
      when "HEAD"
        head(key)
      else
        r(403)
      end
    else # OPTIONS
      r(405)
    end
  end
end
