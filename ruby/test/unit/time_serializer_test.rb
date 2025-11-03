# frozen_string_literal: true

require_relative "../test_helper"

class TimeSerializerTest < TestCase
  setup do
    @serializer = LiveComponent::TimeSerializer.make
  end

  test "serializes" do
    time = Time.new(2025, 9, 20, 10, 30, 0)
    assert_equal(
      { "_lc_ser" => "Time", "value" => time.iso8601(LiveComponent::TimeObjectSerializer::NANO_PRECISION) },
      @serializer.serialize(time)
    )
  end

  test "deserializes" do
    time = Time.new(2025, 9, 20, 10, 30, 0)
    assert_equal(
      time,
      @serializer.deserialize({
        "_lc_ser" => "Time",
        "value" => time.iso8601(LiveComponent::TimeObjectSerializer::NANO_PRECISION)
      })
    )
  end
end
