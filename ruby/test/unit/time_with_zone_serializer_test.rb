# frozen_string_literal: true

require_relative "../test_helper"

class TimeWithZoneSerializerTest < TestCase
  setup do
    @serializer = LiveComponent::TimeWithZoneSerializer.make
  end

  test "serializes" do
    time_with_zone = Time.zone.local(2025, 9, 20, 10, 30, 0)
    assert_equal(
      {
        "_lc_ser" => "ActiveSupport::TimeWithZone",
        "value" => time_with_zone.iso8601(LiveComponent::TimeObjectSerializer::NANO_PRECISION),
        "time_zone" => time_with_zone.time_zone.tzinfo.name
      },

      @serializer.serialize(time_with_zone)
    )
  end

  test "deserializes" do
    time_with_zone = Time.zone.local(2025, 9, 20, 10, 30, 0)
    assert_equal(
      time_with_zone,
      @serializer.deserialize({
        "_lc_ser" => "ActiveSupport::TimeWithZone",
        "value" => time_with_zone.iso8601(LiveComponent::TimeObjectSerializer::NANO_PRECISION),
        "time_zone" => time_with_zone.time_zone.tzinfo.name
      })
    )
  end
end
