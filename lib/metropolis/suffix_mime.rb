module Metropolis::SuffixMime
  MIME_TYPES = Rack::Mime::MIME_TYPES

  def get(key, env)
    set_mime(key, super)
  end

  def head(key, env)
    set_mime(key, super)
  end

  def set_mime(key, response)
    status, headers, _ = response
    200 == status && /(\.[^\.]+)\z/ =~ key and
      type = MIME_TYPES[$1] and headers["Content-Type"] = type
    response
  end
end
