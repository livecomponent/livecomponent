# frozen_string_literal: true

require_relative "../test_helper"

module PayloadTests
  class PayloadTest < TestCase
    test "encode then decode round-trips JSON with compression" do
      json = { "state" => { "props" => { "a" => 1 } }, "reflexes" => [] }.to_json
      encoded = LiveComponent::Payload.encode_payload(json, compress: true)

      decoded, compressed = LiveComponent::Payload.decode_request(encoded)

      assert_equal JSON.parse(json), decoded
      assert compressed
    end

    test "encode then decode round-trips JSON without compression" do
      json = { "state" => {} }.to_json
      encoded = LiveComponent::Payload.encode_payload(json, compress: false)

      decoded, compressed = LiveComponent::Payload.decode_request(encoded)

      assert_equal JSON.parse(json), decoded
      refute compressed
    end

    test "decode detects gzip via magic bytes, not a flag" do
      json = { "k" => "v" }.to_json

      # Compressed input starts with 0x1F 0x8B after base64-decoding
      compressed_encoded = LiveComponent::Payload.encode_payload(json, compress: true)
      raw = Base64.decode64(compressed_encoded)
      assert raw.start_with?([0x1F, 0x8B].pack("C*"))

      # Plain input does not
      plain_encoded = LiveComponent::Payload.encode_payload(json, compress: false)
      raw = Base64.decode64(plain_encoded)
      refute raw.start_with?([0x1F, 0x8B].pack("C*"))
    end

    test "encode compresses by default" do
      json = { "k" => "v" }.to_json
      encoded = LiveComponent::Payload.encode_payload(json)
      _, compressed = LiveComponent::Payload.decode_request(encoded)
      assert compressed
    end

    test "decode raises on malformed JSON" do
      encoded = Base64.encode64("this is not json")
      assert_raises(JSON::ParserError) do
        LiveComponent::Payload.decode_request(encoded)
      end
    end
  end
end
