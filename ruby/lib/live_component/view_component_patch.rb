# frozen_string_literal: true

require "view_component"

module LiveComponent
  module ViewComponentPatch
    def self.included(base)
      base.singleton_class.prepend(ClassMethodOverrides)
    end

    module ClassMethodOverrides
      def new(*args, **kwargs, &block)
        return super unless kwargs[:actions] || kwargs[:targets]

        kwargs = ::LiveComponent::Utils.translate_attrs(Action, kwargs) if kwargs[:actions]
        kwargs = ::LiveComponent::Utils.translate_attrs(Target, kwargs) if kwargs[:targets]

        super
      end
    end
  end
end
