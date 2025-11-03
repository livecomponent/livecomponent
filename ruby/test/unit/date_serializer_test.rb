# frozen_string_literal: true

require_relative "../test_helper"

class DateSerializerTest < TestCase
  setup do
    @serializer = LiveComponent::DateSerializer.make
  end

  test "serializes" do
    date = Date.new(2025, 9, 20)
    assert_equal({ "_lc_ser" => "Date", "value" => "2025-09-20" }, @serializer.serialize(date))
  end

  test "deserializes" do
    date = Date.new(2025, 9, 20)
    assert_equal(date, @serializer.deserialize({ "_lc_ser" => "Date", "value" => "2025-09-20" }))
  end
end
