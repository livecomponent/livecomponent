# frozen_string_literal: true

require "bigdecimal"

module LiveComponent
  class Serializer
    GLOBALID_KEY = "_lc_gid"
    SYMBOL_KEY = "_lc_sym"
    SYMBOL_KEYS_KEY = "_lc_symkeys"
    SYMBOL_HASH_KEY = "_lc_symhash"
    WITH_INDIFFERENT_ACCESS_KEY = "_lc_hwia"

    RESERVED_KEYS = [
      GLOBALID_KEY, GLOBALID_KEY.to_sym,
      SYMBOL_KEYS_KEY, SYMBOL_KEYS_KEY.to_sym,
      SYMBOL_HASH_KEY, SYMBOL_HASH_KEY.to_sym,
      ObjectSerializer::OBJECT_SERIALIZER_KEY, ObjectSerializer::OBJECT_SERIALIZER_KEY.to_sym,
      WITH_INDIFFERENT_ACCESS_KEY, WITH_INDIFFERENT_ACCESS_KEY.to_sym,
    ].to_set

    class << self
      def make
        new
      end
    end

    def initialize
      add_serializer(BigDecimal, BigDecimalSerializer)
      add_serializer(Date, DateSerializer)
      add_serializer(DateTime, DateTimeSerializer)
      add_serializer(ActiveSupport::Duration, DurationSerializer)
      add_serializer(Module, ModuleSerializer)
      add_serializer(Range, RangeSerializer)
      add_serializer(Time, TimeSerializer)
      add_serializer(ActiveSupport::TimeWithZone, TimeWithZoneSerializer)
    end

    def add_serializer(klass, serializer_klass)
      self.serializers[klass] = serializer_klass.make
    end

    def serializers
      @serializers ||= {}
    end

    def serialize(object)
      case object
      when nil, true, false, Integer, Float, String
        object
      when Symbol
        { SYMBOL_KEY => true, "value" => object.name }
      when ActiveRecord::Base, RecordProxy
        default_model_serializer.serialize(object)
      when GlobalID::Identification
        convert_to_global_id_hash(object)
      when Array
        object.map { |elem| serialize(elem) }
      when ActiveSupport::HashWithIndifferentAccess
        serialize_indifferent_hash(object)
      when Hash
        symbol_keys = object.keys
        symbol_keys.select! { |k| k.is_a?(Symbol) }
        symbol_keys.map!(&:name)
        result = serialize_hash(object)

        if Hash.ruby2_keywords_hash?(object)
          result[SYMBOL_HASH_KEY] = true
        else
          result[SYMBOL_KEYS_KEY] = symbol_keys
        end

        result
      else
        if object.respond_to?(:permitted?) && object.respond_to?(:to_h)
          serialize_indifferent_hash(object.to_h)
        elsif serializer = serializers[object.class]
          serializer.serialize(object)
        else
          raise SerializationError, "No serializer found for #{object.class}"
        end
      end
    end

    def deserialize(object)
      case object
      when nil, true, false, String, Integer, Float
        object
      when Array
        object.map { |elem| deserialize(elem) }
      when Hash
        if object[SYMBOL_KEY]
          object["value"].to_sym
        elsif serialized_model?(object)
          default_model_serializer.deserialize(object)
        elsif serialized_global_id?(object)
          deserialize_global_id(object)
        elsif custom_serialized?(object)
          serializer_name = object[ObjectSerializer::OBJECT_SERIALIZER_KEY]
          raise SerializationError, "Serializer name is not present in the object: #{object.inspect}" unless serializer_name

          serializer = lookup_serializer(serializer_name)
          raise SerializationError, "Serializer #{serializer_name} is not known" unless serializer

          serializer.deserialize(object)
        else
          deserialize_hash(object)
        end
      else
        raise SerializationError, "Can only deserialize primitive types, got #{object.inspect}"
      end
    end

    private

    def lookup_serializer(const_str)
      const = const_str.safe_constantize

      if serializers.include?(const)
        serializers[const]
      end
    end

    def serialized_global_id?(hash)
      hash.include?(GLOBALID_KEY)
    end

    def serialized_model?(hash)
      hash.include?(ModelSerializer::MODEL_SERIALIZER_KEY)
    end

    def deserialize_global_id(hash)
      GlobalID::Locator.locate(hash[GLOBALID_KEY])
    end

    def custom_serialized?(hash)
      hash.include?(ObjectSerializer::OBJECT_SERIALIZER_KEY)
    end

    def serialize_hash(object)
      object.each_with_object({}) do |(key, value), hash|
        hash[serialize_hash_key(key)] = serialize(value)
      end
    end

    def deserialize_hash(serialized_hash)
      result = serialized_hash.transform_values { |v| deserialize(v) }

      if result.delete(WITH_INDIFFERENT_ACCESS_KEY)
        result = result.with_indifferent_access
      elsif symbol_keys = result.delete(SYMBOL_KEYS_KEY)
        result = transform_symbol_keys(result, symbol_keys)
      elsif result.delete(SYMBOL_HASH_KEY)
        result.symbolize_keys!
      end

      result
    end

    def serialize_hash_key(key)
      case key
      when RESERVED_KEYS
        raise SerializationError.new("Can't serialize a Hash with reserved key #{key.inspect}")
      when String
        key
      when Symbol
        key.name
      else
        raise SerializationError.new("Only string and symbol hash keys are supported, but #{key.inspect} is a(n) #{key.class}")
      end
    end

    def serialize_indifferent_hash(indifferent_hash)
      result = serialize_hash(indifferent_hash)
      result[WITH_INDIFFERENT_ACCESS_KEY] = true
      result
    end

    def transform_symbol_keys(hash, symbol_keys)
      # NOTE: HashWithIndifferentAccess#transform_keys always
      # returns stringified keys with indifferent access
      # so we call #to_h here to ensure keys are symbolized.
      hash.to_h.transform_keys do |key|
        if symbol_keys.include?(key)
          key.to_sym
        else
          key
        end
      end
    end

    def convert_to_global_id_hash(object)
      { GLOBALID_KEY => object.to_global_id.to_s }
    rescue URI::GID::MissingModelIdError
      raise SerializationError, "Unable to serialize #{object.class} " \
        "without an id. (Maybe you forgot to call save?)"
    end

    def default_model_serializer
      @default_model_serializer ||= ModelSerializer.new
    end
  end
end
