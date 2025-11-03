# frozen_string_literal: true

module LiveComponent
  class TimeSerializer < TimeObjectSerializer
    private

    def hash_to_object(hash)
      Time.iso8601(hash["value"])
    end
  end
end
