# frozen_string_literal: true

require_relative "../test_helper"

module RendererTests
  class RendererTest < TestCase
    def encode_request(state:, reflexes: [], compress: true)
      LiveComponent::Payload.encode(
        { "state" => state, "reflexes" => reflexes }.to_json, compress: compress
      )
    end

    test "renders a component from an encoded payload" do
      encoded = encode_request(state: { "ruby_class" => "HelloWorldComponent", "props" => {} })

      result = LiveComponent::Renderer.render(encoded)

      assert_kind_of LiveComponent::Renderer::Success, result
      raw = Base64.decode64(result.payload)
      assert raw.start_with?([0x1F, 0x8B].pack("C*")), "expected compressed response"
      assert_includes Zlib.gunzip(raw), "Hello, world"
    end

    test "response compression mirrors request compression" do
      encoded = encode_request(
        state: { "ruby_class" => "HelloWorldComponent", "props" => {} }, compress: false
      )

      result = LiveComponent::Renderer.render(encoded)

      assert_kind_of LiveComponent::Renderer::Success, result
      raw = Base64.decode64(result.payload)
      refute raw.start_with?([0x1F, 0x8B].pack("C*")), "expected uncompressed response"
      assert_includes raw, "Hello, world"
    end

    test "dispatches reflexes before rendering" do
      encoded = encode_request(
        state: { "ruby_class" => "ReflexComponent", "props" => {} },
        reflexes: [{ "method_name" => "change", "props" => {} }]
      )

      result = LiveComponent::Renderer.render(encoded)

      assert_kind_of LiveComponent::Renderer::Success, result
      html = Zlib.gunzip(Base64.decode64(result.payload))
      assert_includes html, "Changed"
      refute_includes html, "<p>Start</p>"
    end

    test "returns Failure when the component raises" do
      encoded = encode_request(state: { "ruby_class" => "BoomComponent", "props" => {} })

      result = LiveComponent::Renderer.render(encoded)

      assert_kind_of LiveComponent::Renderer::Failure, result
      assert_equal "boom", result.message
      assert_equal "RuntimeError", result.error_class
      assert_kind_of Array, result.backtrace
    end

    test "returns Failure on a malformed payload" do
      result = LiveComponent::Renderer.render(Base64.encode64("not json"))

      assert_kind_of LiveComponent::Renderer::Failure, result
      assert_equal "JSON::ParserError", result.error_class
    end
  end
end
