# frozen_string_literal: true

module LiveComponent
  class DateSerializer < ObjectSerializer
    private

    def object_to_hash(date)
      { "value" => date.iso8601 }
    end

    def hash_to_object(hash)
      Date.iso8601(hash["value"])
    end
  end
end
