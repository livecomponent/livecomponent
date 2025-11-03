# frozen_string_literal: true

module LiveComponent
  class ModuleSerializer < ObjectSerializer
    private

    def object_to_hash(constant)
      { "value" => constant.name }
    end

    def hash_to_object(hash)
      hash["value"].constantize
    end
  end
end
