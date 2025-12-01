# frozen_string_literal: true

module LiveComponent
  class Target
    def initialize(controller_name, target_name)
      @controller_name = controller_name
      @target_name = target_name
    end

    def to_attributes
      { "data-#{@controller_name}-target": @target_name.to_s }
    end

    def self.attr_name
      :targets
    end

    def attr_name
      self.class.attr_name
    end
  end
end
