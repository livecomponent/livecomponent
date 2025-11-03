# frozen_string_literal: true

require_relative "../test_helper"

class RangeSerializerTest < TestCase
  setup do
    @serializer = LiveComponent::RangeSerializer.make
  end

  test "serializes inclusive" do
    range = 1..2
    assert_equal(
      { "_lc_ser" => "Range", "begin" => 1, "end" => 2, "exclude_end" => false },
      @serializer.serialize(range)
    )
  end

  test "serializes exclusive" do
    range = 1...2
    assert_equal(
      { "_lc_ser" => "Range", "begin" => 1, "end" => 2, "exclude_end" => true },
      @serializer.serialize(range)
    )
  end

  test "deserializes inclusive" do
    range = 1..2
    assert_equal(
      range,
      @serializer.deserialize({ "_lc_ser" => "Range", "begin" => 1, "end" => 2, "exclude_end" => false })
    )
  end

  test "deserializes exclusive" do
    range = 1...2
    assert_equal(
      range,
      @serializer.deserialize({ "_lc_ser" => "Range", "begin" => 1, "end" => 2, "exclude_end" => true })
    )
  end
end
