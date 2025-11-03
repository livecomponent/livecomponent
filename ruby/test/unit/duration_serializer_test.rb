# frozen_string_literal: true

require_relative "../test_helper"

class DurationSerializerTest < TestCase
  setup do
    @serializer = LiveComponent::DurationSerializer.make
  end

  test "serializes" do
    duration = 1.month

    assert_equal(
      {
        "_lc_ser" => "ActiveSupport::Duration",
        "value" => 2629746,
        "parts" => [[{ "_lc_sym" => true, "value" => "months" }, 1]]
      },

      @serializer.serialize(duration)
    )
  end

  test "deserializes" do
    duration = 1.month

    assert_equal(
      duration,
      @serializer.deserialize({
        "_lc_ser" => "ActiveSupport::Duration",
        "value" => 2629746,
        "parts" => [[{ "_lc_sym" => true, "value" => "months" }, 1]]
      })
    )
  end
end
