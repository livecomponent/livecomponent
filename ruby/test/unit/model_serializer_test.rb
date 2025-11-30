# frozen_string_literal: true

require_relative "../test_helper"

class ModelSerializerTest < TestCase
  test "serializes all attributes by default" do
    record = TodoList.create(name: "Groceries")
    serializer = LiveComponent::ModelSerializer.new
    hash = serializer.serialize(record)

    assert_includes(hash, "_lc_ar")

    global_id = hash["_lc_ar"]
    assert_includes(global_id, "gid")
    assert_equal(true, global_id["signed"])

    assert_equal(record.id, hash["id"])
    assert_equal("Groceries", hash["name"])
    assert_includes(hash, "created_at")
    assert_includes(hash, "updated_at")
  end

  test "serializes no attributes if configured" do
    record = TodoList.create(name: "Groceries")
    serializer = LiveComponent::ModelSerializer.new(attributes: false)
    hash = serializer.serialize(record)

    refute_includes(hash, "name")
    refute_includes(hash, "created_at")
    refute_includes(hash, "updated_at")
  end

  test "serializes only the configured attributes" do
    record = TodoList.create(name: "Groceries")
    serializer = LiveComponent::ModelSerializer.new(attributes: [:name])
    hash = serializer.serialize(record)

    assert_includes(hash, "name")
    refute_includes(hash, "created_at")
    refute_includes(hash, "updated_at")
  end

  test "signs by default" do
    record = TodoList.create(name: "Groceries")
    serializer = LiveComponent::ModelSerializer.new
    hash = serializer.serialize(record)

    assert_equal(true, hash.dig("_lc_ar", "signed"))

    # assert starts with base64-encoded open curly brace and double quote
    assert(hash.dig("_lc_ar", "gid").start_with?("ey"))
  end

  test "does not sign when configured not to" do
    record = TodoList.create(name: "Groceries")
    serializer = LiveComponent::ModelSerializer.new(sign: false)
    hash = serializer.serialize(record)

    assert_equal(false, hash.dig("_lc_ar", "signed"))
    assert_equal("gid://dummy/TodoList/#{record.id}", hash.dig("_lc_ar", "gid"))
  end

  test "deserializing does not load the record by default" do
    record = TodoList.create(name: "Groceries")
    serializer = LiveComponent::ModelSerializer.new(sign: false)
    hash = serializer.serialize(record)

    assert_no_queries do
      serializer.deserialize(hash)
    end
  end

  test "deserializing reloads the record when configured to do so" do
    record = TodoList.create(name: "Groceries")
    serializer = LiveComponent::ModelSerializer.new(reload: true)
    hash = serializer.serialize(record)

    assert_queries_count(1) do
      serializer.deserialize(hash)
    end
  end

  test "deserializing returns a RecordProxy" do
    record = TodoList.create(name: "Groceries")
    serializer = LiveComponent::ModelSerializer.new
    hash = serializer.serialize(record)

    assert_equal(LiveComponent::RecordProxy, serializer.deserialize(hash).class)
  end

  test "deserializing with reload: true returns an instance of the model class" do
    record = TodoList.create(name: "Groceries")
    serializer = LiveComponent::ModelSerializer.new(reload: true)
    hash = serializer.serialize(record)

    assert_equal(TodoList, serializer.deserialize(hash).class)
  end
end
