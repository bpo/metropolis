# -*- encoding: binary -*-
module Metropolis::Constants

  # response headers, frozen for speed since they're settable hash keys
  Content_Length = "Content-Length".freeze
  Content_Type = "Content-Type".freeze
  Content_Encoding = "Content-Encoding".freeze
  Vary = "Vary".freeze

  Text_Plain = "text/plain"
  Accept_Encoding = "Accept-Encoding"

  # request headers, no need to freeze since we only read them
  Rack_Input = "rack.input"
  PATH_INFO = "PATH_INFO"
  REQUEST_METHOD = "REQUEST_METHOD"
  HTTP_ACCEPT_ENCODING = "HTTP_ACCEPT_ENCODING"
  HTTP_CONTENT_ENCODING = "HTTP_CONTENT_ENCODING"
  HTTP_X_TT_PDMODE = "HTTP_X_TT_PDMODE"
end
