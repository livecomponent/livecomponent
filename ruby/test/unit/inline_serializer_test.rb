# frozen_string_literal: true

require_relative "../test_helper"

class InlineSerializerTest < TestCase
  class Thing
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  setup do
    @serializer = LiveComponent::InlineSerializer::Builder
      .new
      .serialize { |thing| { "_lc_thing" => true, "value" => thing.value } }
      .deserialize { |hash| Thing.new(hash["value"]) }
      .to_serializer
  end

  test "serializes" do
    assert_equal(
      { "_lc_thing" => true, "value" => "foo" },
      @serializer.serialize(Thing.new("foo"))
    )
  end

  test "deserializes" do
    result = @serializer.deserialize({ "_lc_thing" => true, "value" => "foo" })
    assert_equal Thing, result.class
    assert_equal "foo", result.value
  end
end
