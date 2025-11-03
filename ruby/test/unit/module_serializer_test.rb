# frozen_string_literal: true

require_relative "../test_helper"

class ModuleSerializerTest < TestCase
  module TestMod
  end

  setup do
    @serializer = LiveComponent::ModuleSerializer.make
  end

  test "serializes" do
    assert_equal(
      { "_lc_ser" => "Module", "value" => "ModuleSerializerTest::TestMod" },
      @serializer.serialize(TestMod)
    )
  end

  test "deserializes" do
    assert_equal(
      TestMod,
      @serializer.deserialize({ "_lc_ser" => "Module", "value" => "ModuleSerializerTest::TestMod" })
    )
  end
end
