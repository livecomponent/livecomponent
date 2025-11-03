# frozen_string_literal: true

module LiveComponent
  class TimeObjectSerializer < ObjectSerializer
    NANO_PRECISION = 9

    private

    def object_to_hash(time)
      { "value" => time.iso8601(NANO_PRECISION) }
    end
  end
end
