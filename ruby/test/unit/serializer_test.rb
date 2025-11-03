# frozen_string_literal: true

require_relative "../test_helper"

module SerializerTests
  class Thing
    include GlobalID::Identification

    attr_reader :id

    def initialize(id)
      @id = id
    end

    def to_global_id
      GlobalID.create(self)
    end

    def self.find(id)
      new(id.to_i)
    end
  end

  class TestObject
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  class TestObjectSerializer < LiveComponent::ObjectSerializer
    private

    def object_to_hash(object)
      { "value" => object.value }
    end

    def hash_to_object(hash)
      TestObject.new(hash["value"])
    end
  end

  class SerializeTest < TestCase
    def serialize(object)
      LiveComponent.serializer.serialize(object)
    end

    teardown do
      LiveComponent.instance_variable_set(:@serializer, nil)
    end

    test "serializes basic types" do
      assert_nil serialize(nil)
      assert_equal true, serialize(true)
      assert_equal false, serialize(false)
      assert_equal 1, serialize(1)
      assert_equal 1.1, serialize(1.1)
      assert_equal "foo", serialize("foo")
    end

    test "serializes symbols" do
      assert_equal({ "_lc_sym" => true, "value" => "foo" }, serialize(:foo))
    end

    test "serializes activerecord models, includes attributes by default" do
      todo_list = TodoList.create(name: "Groceries")
      result = serialize(todo_list)

      assert_equal todo_list.id, result["id"]
      assert_equal todo_list.name, result["name"]
    end

    test "activerecord GIDs are signed by default" do
      todo_list = TodoList.create(name: "Groceries")
      result = serialize(todo_list)

      assert_includes result, "_lc_ar"
      assert_includes result["_lc_ar"], "gid"
      assert result["_lc_ar"]["signed"]
    end

    test "serializes global IDs" do
      assert_equal(
        { "_lc_gid" => "gid://dummy/SerializerTests::Thing/1" },
        serialize(Thing.new(1))
      )
    end

    test "serializes arrays with basic types" do
      assert_equal(["item 1", "item 2"], serialize(["item 1", "item 2"]))
    end

    test "serializes arrays with complex types" do
      assert_equal(
        [{ "_lc_sym" => true, "value" => "item1" }, { "_lc_sym" => true, "value" => "item2"}],
        serialize([:item1, :item2])
      )
    end

    test "serializes a HashWithIndifferentAccess with symbol keys" do
      assert_equal(
        { "_lc_hwia" => true, "key" => "value" },
        serialize(HashWithIndifferentAccess.new({ key: "value" })),
      )
    end

    test "serializes a HashWithIndifferentAccess with string keys" do
      assert_equal(
        { "_lc_hwia" => true, "key" => "value" },
        serialize(HashWithIndifferentAccess.new({ "key" => "value" })),
      )
    end

    test "raises an error when serializing a HashWithIndifferentAccess with non string, non symbol keys" do
      error = assert_raises(LiveComponent::SerializationError) do
        serialize(HashWithIndifferentAccess.new({ 1 => "value" }))
      end

      assert_equal(
        "Only string and symbol hash keys are supported, but 1 is a(n) Integer",
        error.message,
      )
    end

    test "serializes a hash with symbol and string keys" do
      assert_equal(
        { "_lc_symkeys" => ["sym_key"], "sym_key" => "sym value", "string_key" => "string value" },
        serialize({ sym_key: "sym value", "string_key" => "string value" }),
      )
    end

    test "serializes a ruby v2+ keywords hash with symbol and string keys" do
      assert_equal(
        { "_lc_kwargs" => ["sym_key"], "sym_key" => "sym value", "string_key" => "string value" },
        serialize(Hash.ruby2_keywords_hash({ sym_key: "sym value", "string_key" => "string value" }))
      )
    end

    test "serializes with a custom serializer" do
      LiveComponent.serializer.add_serializer(TestObject, TestObjectSerializer)
      assert_equal(
        { "_lc_ser" => "SerializerTests::TestObject", "value" => "value" },
        serialize(TestObject.new("value"))
      )
    end

    test "raises an error when no serializer can be found for the given object" do
      error = assert_raises(LiveComponent::SerializationError) do
        serialize(TestObject.new("value"))
      end

      assert_equal "No serializer found for SerializerTests::TestObject", error.message
    end
  end

  class DeserializeTest < TestCase
    def serialize(object)
      LiveComponent.serializer.serialize(object)
    end

    def deserialize(hash)
      LiveComponent.serializer.deserialize(hash)
    end

    teardown do
      LiveComponent.instance_variable_set(:@serializer, nil)
    end

    test "deserializes basic types" do
      assert_nil deserialize(nil)
      assert_equal true, deserialize(true)
      assert_equal false, deserialize(false)
      assert_equal 1, deserialize(1)
      assert_equal 1.1, deserialize(1.1)
      assert_equal "foo", deserialize("foo")
    end

    test "deserializes symbols" do
      assert_equal(:foo, deserialize({ "_lc_sym" => true, "value" => "foo" }))
    end

    test "deserializes activerecord models into record proxies" do
      todo_list = TodoList.create(name: "Groceries")
      serialized = serialize(todo_list)
      proxy = deserialize(serialized)

      assert_equal LiveComponent::RecordProxy, proxy.class
      assert_equal TodoList, proxy.load.class
    end

    test "deserializes global IDs" do
      result = deserialize({ "_lc_gid" => "gid://dummy/SerializerTests::Thing/1" })
      assert_equal Thing, result.class
      assert_equal 1, result.id
    end

    test "deserializes arrays with basic types" do
      assert_equal(["item 1", "item 2"], deserialize(["item 1", "item 2"]))
    end

    test "deserializes arrays with complex types" do
      assert_equal(
        [:item1, :item2],
        deserialize([{ "_lc_sym" => true, "value" => "item1" }, { "_lc_sym" => true, "value" => "item2"}]),
      )
    end

    test "deserializes a HashWithIndifferentAccess with symbol keys" do
      assert_equal(
        HashWithIndifferentAccess.new({ key: "value" }),
        deserialize({ "_lc_hwia" => true, "key" => "value" }),
      )
    end

    test "deserializes a HashWithIndifferentAccess with string keys" do
      assert_equal(
        HashWithIndifferentAccess.new({ "key" => "value" }),
        deserialize({ "_lc_hwia" => true, "key" => "value" }),
      )
    end

    test "deserializes a hash with symbol and string keys" do
      assert_equal(
        { sym_key: "sym value", "string_key" => "string value" },
        deserialize({ "_lc_symkeys" => ["sym_key"], "sym_key" => "sym value", "string_key" => "string value" }),
      )
    end

    test "deserializes a ruby v2+ keywords hash with symbol and string keys" do
      result = deserialize({ "_lc_kwargs" => ["sym_key"], "sym_key" => "sym value", "string_key" => "string value" })

      assert_equal(
        { sym_key: "sym value", "string_key" => "string value" },
        result,
      )

      assert Hash.ruby2_keywords_hash?(result)
    end

    test "deserializes with a custom serializer" do
      LiveComponent.serializer.add_serializer(TestObject, TestObjectSerializer)
      result = deserialize({ "_lc_ser" => "SerializerTests::TestObject", "value" => "value" })

      assert_equal TestObject, result.class
      assert_equal "value", result.value
    end

    test "raises an error if no serializer has been registered for the given type" do
      error = assert_raises(LiveComponent::SerializationError) do
        deserialize({ "_lc_ser" => "DefaultSerializerTests::TestObject", "value" => "value" })
      end

      assert_equal "Serializer DefaultSerializerTests::TestObject is not known", error.message
    end

    test "raises an error if given a non-primitive type" do
      error = assert_raises(LiveComponent::SerializationError) do
        deserialize(:nope)
      end

      assert_equal "Can only deserialize primitive types, got :nope", error.message
    end
  end
end
