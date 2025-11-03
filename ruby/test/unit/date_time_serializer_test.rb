# frozen_string_literal: true

require_relative "../test_helper"

class DateTimeSerializerTest < TestCase
  setup do
    @serializer = LiveComponent::DateTimeSerializer.make
  end

  test "serializes" do
    date_time = DateTime.new(2025, 9, 20, 10, 30, 0)
    assert_equal(
      { "_lc_ser" => "DateTime", "value" => date_time.iso8601(LiveComponent::TimeObjectSerializer::NANO_PRECISION) },
      @serializer.serialize(date_time)
    )
  end

  test "deserializes" do
    date_time = DateTime.new(2025, 9, 20, 10, 30, 0)
    assert_equal(
      date_time,
      @serializer.deserialize({
        "_lc_ser" => "DateTime",
        "value" => date_time.iso8601(LiveComponent::TimeObjectSerializer::NANO_PRECISION)
      })
    )
  end
end
