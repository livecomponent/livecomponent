# frozen_string_literal: true

require "base64"
require "zlib"
require "json"

module LiveComponent
  # Encoding/decoding for the two payload directions used by the JS client.
  # The wire formats are NOT symmetric:
  #
  #   request:  base64(gzip?(JSON))       -- decoded by #decode_request
  #   response: base64(gzip?(raw HTML))   -- produced by #encode_response
  #
  # Each method is named for the direction it serves, so a call site that
  # reaches for the wrong one reads wrong. In particular, do not JSON-encode
  # the argument to #encode_response: the JS client's decode_response()
  # never JSON-parses, and would render the escaped JSON string instead of
  # markup.
  module Payload
    GZIP_MAGIC_BYTES = [0x1F, 0x8B].pack("C*").freeze

    class << self
      # REQUEST side only. Expects base64(gzip?(JSON)) and JSON-parses the
      # result. Never call this on a response payload.
      def decode_request(data)
        data = Base64.decode64(data)
        compressed = gzipped?(data)
        data = Zlib.gunzip(data) if compressed
        [JSON.parse(data), compressed]
      end

      # RESPONSE side only. `data` must already be raw HTML (a String), not
      # JSON -- this only base64/gzip-encodes it, it does not serialize.
      def encode_response(data, compress: true)
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
