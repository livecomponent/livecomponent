# frozen_string_literal: true

require_relative "../test_helper"
require "bigdecimal"

class BigDecimalSerializerTest < TestCase
  setup do
    @serializer = LiveComponent::BigDecimalSerializer.make
  end

  test "serializes" do
    decimal = BigDecimal("12.34")
    assert_equal({ "_lc_ser" => "BigDecimal", "value" => "12.34" }, @serializer.serialize(decimal))
  end

  test "deserializes" do
    decimal = BigDecimal("12.34")
    assert_equal(decimal, @serializer.deserialize({ "_lc_ser" => "BigDecimal", "value" => "12.34" }))
  end
end
