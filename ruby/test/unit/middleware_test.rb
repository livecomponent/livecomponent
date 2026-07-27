# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

module MiddlewareTests
  class MiddlewareTest < TestCase
    DOWNSTREAM = ->(env) { [200, { "Content-Type" => "text/plain" }, ["downstream"]] }

    def middleware
      LiveComponent::Middleware.new(DOWNSTREAM)
    end

    def env_for(body, path: "/live_component/render")
      { "PATH_INFO" => path, "rack.input" => StringIO.new(body) }
    end

    def encode_request(state:, reflexes: [])
      LiveComponent::Payload.encode_payload({ "state" => state, "reflexes" => reflexes }.to_json)
    end

    test "renders and returns 200 with encoded payload body" do
      encoded = encode_request(state: { "ruby_class" => "HelloWorldComponent", "props" => {} })
      body = { "payload" => encoded }.to_json

      status, headers, response_body = middleware.call(env_for(body))

      assert_equal 200, status
      assert_equal "text/html", headers["Content-Type"]
      html = Zlib.gunzip(Base64.decode64(response_body.first))
      assert_includes html, "Hello, world"
    end

    test "returns 500 with error headers when the render fails" do
      encoded = encode_request(state: { "ruby_class" => "BoomComponent", "props" => {} })
      body = { "payload" => encoded }.to_json

      status, headers, response_body = middleware.call(env_for(body))

      assert_equal 500, status
      assert_equal "boom (RuntimeError)", headers["X-Live-Error-Message"]
      assert_kind_of Array, JSON.parse(headers["X-Live-Error-Backtrace-Json"])
      assert_includes response_body.first, "boom (RuntimeError)"
    end

    test "returns 500 when the request envelope is not JSON" do
      status, headers, = middleware.call(env_for("not json at all"))

      assert_equal 500, status
      assert_includes headers["X-Live-Error-Message"], "JSON::ParserError"
    end

    test "passes other paths through to the app" do
      status, _, body = middleware.call(env_for("", path: "/anything/else"))

      assert_equal 200, status
      assert_equal ["downstream"], body
    end
  end
end
