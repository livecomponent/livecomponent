# frozen_string_literal: true

require "base64"
require "zlib"
require "json"

module LiveComponent
  module Payload
    GZIP_MAGIC_BYTES = [0x1F, 0x8B].pack("C*").freeze

    class << self
      def decode(data)
        data = Base64.decode64(data)
        compressed = gzipped?(data)
        data = Zlib.gunzip(data) if compressed
        [JSON.parse(data), compressed]
      end

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
