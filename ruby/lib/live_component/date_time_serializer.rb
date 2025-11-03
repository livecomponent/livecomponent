# frozen_string_literal: true

module LiveComponent
  class DateTimeSerializer < TimeObjectSerializer
    private

    def hash_to_object(hash)
      DateTime.iso8601(hash["value"])
    end
  end
end
