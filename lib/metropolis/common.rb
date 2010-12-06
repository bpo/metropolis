# -*- encoding: binary -*-
module Metropolis::Common
  include Rack::Utils # unescape
  autoload :RO, 'metropolis/common/ro'

  def setup(opts)
    @headers = { 'Content-Type' => 'application/octet-stream' }
    @headers.merge!(opts[:response_headers] || {})
    @nr_slots = opts[:nr_slots]

    if @path_pattern
      @nr_slots ||= 3
      @uri.path == '/' or
        raise ArgumentError, ":path_pattern may only be used if path is '/'"
      @path_pattern.scan(/%\d*x/).size == 1 or
        raise ArgumentError, "only one '/%\d*x/' may appear in #@path_pattern"
    else
      @nr_slots and
        raise ArgumentError, ":nr_slots may be used with :path_pattern"
    end

    @readonly = !!opts[:readonly]
    @exclusive = !!opts[:exclusive]
    if @readonly && @exclusive
      raise ArgumentError, ":readonly and :exclusive may not be used together"
    end
    case @encoding = opts[:encoding]
    when nil
    when :deflate
      extend(Metropolis::Deflate)
    when :gzip
      extend(Metropolis::Gzip)
    else
      raise ArgumentError, "unsupported encoding"
    end
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
        get(key, env)
      when "HEAD"
        head(key, env)
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

  # generic HEAD implementation, some databases can optimize this by
  # not retrieving the value
  def head(key, env)
    r = get(key, env)
    r[2].clear
    r
  end
end
