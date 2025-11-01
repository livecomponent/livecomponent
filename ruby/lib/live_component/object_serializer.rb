# frozen_string_literal: true

module LiveComponent
  class ObjectSerializer
    OBJECT_SERIALIZER_KEY = "_lc_ser"

    def self.make(...)
      new(...)
    end

    def serialize(object)
      { OBJECT_SERIALIZER_KEY => object.class.name }.merge!(object_to_hash(object))
    end

    def deserialize(hash)
      hash_to_object(hash)
    end

    private

    def object_to_hash(_object)
      raise NotImplementedError, "please define #{__method__} in derived classes"
    end

    def hash_to_object(_hash)
      raise NotImplementedError, "please define #{__method__} in derived classes"
    end
  end
end
