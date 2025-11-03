# frozen_string_literal: true

module LiveComponent
  class RangeSerializer < ObjectSerializer
    private

    def object_to_hash(range)
      {
        "begin" => LiveComponent.serializer.serialize(range.begin),
        "end" => LiveComponent.serializer.serialize(range.end),
        "exclude_end" => range.exclude_end?, # Always boolean, no need to serialize
      }
    end

    def hash_to_object(hash)
      Range.new(*LiveComponent.serializer.deserialize([hash["begin"], hash["end"]]), hash["exclude_end"])
    end
  end
end
