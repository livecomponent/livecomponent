require "live_component"

module LiveComponent
  class Engine < ::Rails::Engine
    isolate_namespace LiveComponent

    initializer "live-component.include_helpers" do
      ActiveSupport.on_load(:action_controller) do
        helper LiveComponent::ApplicationHelper
        include LiveComponent::ControllerMethods
      end
    end

    initializer "live-component.patch_vc" do
      ActiveSupport.on_load(:view_component) do
        include LiveComponent::ViewComponentPatch
        include LiveComponent::ApplicationHelper
      end
    end
  end
end
