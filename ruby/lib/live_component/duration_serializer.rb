# frozen_string_literal: true

module LiveComponent
  class DurationSerializer < ObjectSerializer
    private

    def object_to_hash(duration)
      { "value" => duration.value, "parts" => LiveComponent.serializer.serialize(duration.parts.to_a) }
    end

    def hash_to_object(hash)
      value = hash["value"]
      parts = LiveComponent.serializer.deserialize(hash["parts"].to_h)
      # `parts` is originally a hash, but will have been flattened to an array by serializer.deserialize
      ActiveSupport::Duration.new(value, parts.to_h)
    end
  end
end
