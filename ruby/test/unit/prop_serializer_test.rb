# frozen_string_literal: true

require_relative "../test_helper"

class PropSerializerTest < TestCase
  class Thing
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  class ThingSerializer < LiveComponent::ObjectSerializer
    def initialize(**options)
      @options = options
    end

    private

    def object_to_hash(thing)
      { "value" => thing.value, **@options }
    end

    def hash_to_object(hash)
      Thing.new(hash["value"])
    end
  end

  teardown do
    LiveComponent.instance_variable_set(:@registered_prop_serializers, nil)
  end

  test "serializes props using configured serializers" do
    LiveComponent.register_prop_serializer(:thing_serializer, ThingSerializer)

    component_class = Class.new(ViewComponent::Base) do
      include LiveComponent::Base

      serializes :thing, with: :thing_serializer
    end

    assert_equal(
      { thing: { "_lc_ser" => "PropSerializerTest::Thing", "value" => "foo" } },
      component_class.serialize_props({ thing: Thing.new("foo") })
    )
  end

  test "deserializes props using configured serializers" do
    LiveComponent.register_prop_serializer(:thing_serializer, ThingSerializer)

    component_class = Class.new(ViewComponent::Base) do
      include LiveComponent::Base

      serializes :thing, with: :thing_serializer
    end

    result = component_class.deserialize_props(
      { thing: { "_lc_ser" => "PropSerializerTest::Thing", "value" => "foo" } }
    )

    assert_equal Hash, result.class
    assert_equal Thing, result[:thing].class
    assert_equal "foo", result[:thing].value
  end

  test "prop serializers can accept custom options" do
    LiveComponent.register_prop_serializer(:thing_serializer, ThingSerializer)

    component_class = Class.new(ViewComponent::Base) do
      include LiveComponent::Base

      serializes :thing, with: :thing_serializer, custom_option: "custom value"
    end

    assert_equal(
      { thing: { "_lc_ser" => "PropSerializerTest::Thing", "value" => "foo", custom_option: "custom value" } },
      component_class.serialize_props({ thing: Thing.new("foo") })
    )
  end

  test "prop serializers can be defined inline" do
    component_class = Class.new(ViewComponent::Base) do
      include LiveComponent::Base

      serializes :thing, custom_option: "custom value" do |serializer, **options|
        serializer.serialize do |thing|
          { "_lc_thing" => true, "value" => thing.value, **options }
        end

        serializer.deserialize do |hash|
          # here to distinguish the inline serializer from the registered one in the tests above
          unless hash.include?("_lc_thing")
            raise "Expected to find _lc_thing in the serialized hash"
          end

          Thing.new(hash["value"])
        end
      end
    end

    assert_equal(
      { thing: { "_lc_thing" => true, "value" => "foo", custom_option: "custom value" } },
      component_class.serialize_props({ thing: Thing.new("foo") })
    )

    result = component_class.deserialize_props(
      { thing: { "_lc_thing" => true, "value" => "foo", custom_option: "custom value" } }
    )

    assert_equal Hash, result.class
    assert_equal Thing, result[:thing].class
    assert_equal "foo", result[:thing].value
  end

  test "inline serializers must be passed one of a block or the with: argument" do
    error = assert_raises(RuntimeError) do
      Class.new(ViewComponent::Base) do
        include LiveComponent::Base
        serializes :thing
      end
    end

    assert_equal(
      "Expected `serializes' to be called with a block or the with: parameter",
      error.message
    )
  end

  test "inline serializers cannot be passed both a block and the with: argument" do
    error = assert_raises(RuntimeError) do
      Class.new(ViewComponent::Base) do
        include LiveComponent::Base
        serializes :thing, with: :some_serializer do |*|
        end
      end
    end

    assert_equal(
      "Expected `serializes' to be called with a block or the with: parameter, but both were provided",
      error.message
    )
  end

  test "raises an error if the given prop serializer could not be found" do
    error = assert_raises(RuntimeError) do
      Class.new(ViewComponent::Base) do
        include LiveComponent::Base
        serializes :thing, with: :non_existent_serializer
      end
    end

    assert_equal(
      "Could not find a serializer with the name 'non_existent_serializer' - is it registered?",
      error.message
    )
  end
end
