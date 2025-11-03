# frozen_string_literal: true

module LiveComponent
  class TimeWithZoneSerializer < ObjectSerializer
    NANO_PRECISION = 9

    private

    def object_to_hash(time_with_zone)
      {
        "value" => time_with_zone.iso8601(NANO_PRECISION),
        "time_zone" => time_with_zone.time_zone.tzinfo.name
      }
    end

    def hash_to_object(hash)
      Time.iso8601(hash["value"]).in_time_zone(hash["time_zone"] || Time.zone)
    end
  end
end
