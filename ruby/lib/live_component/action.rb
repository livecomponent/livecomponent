# frozen_string_literal: true

module LiveComponent
  class Action
    def initialize(controller_name, event_name)
      @controller_name = controller_name
      @event_name = event_name
    end

    def call(method_name)
      @method_name = method_name
      self
    end

    def self.attr_name
      :actions
    end

    def attr_name
      self.class.attr_name
    end

    def to_attributes
      {}.tap do |attrs|
        if @method_name
          attrs[:"data-action"] = "#{@event_name}->#{@controller_name}##{@method_name}"
        end
      end
    end
  end
end
