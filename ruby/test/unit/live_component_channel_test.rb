# frozen_string_literal: true

require_relative "../test_helper"

module LiveComponentChannelTests
  class LiveComponentChannelTest < ActionCable::Channel::TestCase
    tests LiveComponentChannel

    def encode_request(state:, reflexes: [])
      LiveComponent::Payload.encode({ "state" => state, "reflexes" => reflexes }.to_json)
    end

    test "does not stream from any global broadcasting" do
      subscribe
      assert subscription.confirmed?
      assert_no_streams
    end

    test "transmits the rendered payload with the request_id" do
      subscribe
      encoded = encode_request(state: { "ruby_class" => "HelloWorldComponent", "props" => {} })

      perform :receive, { "payload" => encoded, "request_id" => "req-1" }

      response = transmissions.last
      assert_equal "req-1", response["request_id"]
      html = Zlib.gunzip(Base64.decode64(response["payload"]))
      assert_includes html, "Hello, world"
    end

    test "transmits an error hash when the render fails" do
      subscribe
      encoded = encode_request(state: { "ruby_class" => "BoomComponent", "props" => {} })

      perform :receive, { "payload" => encoded, "request_id" => "req-2" }

      response = transmissions.last
      assert_equal "req-2", response["request_id"]
      assert_equal "boom", response["error"]["message"]
      assert_kind_of Array, response["error"]["backtrace"]
    end

    test "transmits an error hash when the envelope is malformed" do
      subscribe

      perform :receive, { "payload" => nil, "request_id" => "req-3" }

      response = transmissions.last
      assert_equal "req-3", response["request_id"]
      assert response["error"]["message"].present?
    end
  end
end
