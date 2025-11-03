# frozen_string_literal: true

require "bigdecimal"

module LiveComponent
  class BigDecimalSerializer < ObjectSerializer
    private

    def object_to_hash(big_decimal)
      { "value" => big_decimal.to_s }
    end

    def hash_to_object(hash)
      BigDecimal(hash["value"])
    end
  end
end
