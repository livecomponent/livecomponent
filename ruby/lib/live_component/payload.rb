# frozen_string_literal: true

require "base64"
require "zlib"
require "json"

module LiveComponent
  # Encoding/decoding for the two payload directions used by the JS client.
  # The wire formats are NOT symmetric, despite the module's shared naming:
  #
  #   request:  base64(gzip?(JSON))       -- decoded by #decode below
  #   response: base64(gzip?(raw HTML))   -- produced by #encode below
  #
  # Do not use #decode on a response body (it will JSON-parse HTML and
  # blow up), and do not JSON-encode the argument to #encode (the JS
  # client's decode() never JSON-parses and will render the escaped
  # JSON string instead of markup).
  module Payload
    GZIP_MAGIC_BYTES = [0x1F, 0x8B].pack("C*").freeze

    class << self
      # REQUEST side only. Expects base64(gzip?(JSON)) and JSON-parses the
      # result. Never call this on a response payload.
      def decode(data)
        data = Base64.decode64(data)
        compressed = gzipped?(data)
        data = Zlib.gunzip(data) if compressed
        [JSON.parse(data), compressed]
      end

      # RESPONSE side only. `data` must already be raw HTML (a String), not
      # JSON -- this only base64/gzip-encodes it, it does not serialize.
      def encode(data, compress: true)
        data = Zlib.gzip(data) if compress
        Base64.encode64(data)
      end

      private

      def gzipped?(data)
        data.start_with?(GZIP_MAGIC_BYTES)
      end
    end
  end
end
