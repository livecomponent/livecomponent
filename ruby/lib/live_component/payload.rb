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
        data = Zlib.gunzip(data) if gzipped?(data)
        JSON.parse(data)
      end

      def encode(data)
        Base64.encode64(Zlib.gzip(data))
      end

      private

      def gzipped?(data)
        data.start_with?(GZIP_MAGIC_BYTES)
      end
    end
  end
end
