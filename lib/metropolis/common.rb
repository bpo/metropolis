# -*- encoding: binary -*-
module Metropolis::Common
  include Rack::Utils # unescape

  def setup(opts)
    @uri = opts[:uri]
    @headers = { 'Content-Type' => 'application/octet-stream' }
    @headers.merge!(opts[:response_headers] || {})
    @nr_slots = opts[:nr_slots] || 3
    @readonly = !!opts[:readonly]
  end

  def r(code, body = nil)
    body ||= "#{HTTP_STATUS_CODES[code]}\n"
    [ code,
      { 'Content-Length' => body.size.to_s, 'Content-Type' => 'text/plain' },
      [ body ] ]
  end

  def call(env)
    if %r{\A/(.*)\z} =~ env["PATH_INFO"]
      key = unescape($1)
      case env["REQUEST_METHOD"]
      when "GET"
        get(key)
      when "HEAD"
        head(key)
      when "DELETE"
        delete(key)
      when "PUT"
        put(key, env)
      else
        r(405)
      end
    else # OPTIONS
      r(405)
    end
  end
end
