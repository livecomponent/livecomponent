# frozen_string_literal: true

module LiveComponent
  class TagBuilder
    def initialize(controller)
      @controller = controller
    end

    def rerender(**kwargs, &block)
      state = JSON.parse(@controller.params[:__lc_rerender_state])
      id = @controller.params[:__lc_rerender_id]
      state["props"]["__lc_attributes"] = { "data-id" => id }

      component = LiveComponent::RenderComponent.new(state, [], kwargs)

      # We have to render a turbo stream so Turbo doesn't append this to the <html> tag
      @controller.turbo_stream.update(:this_id_shouldnt_exist, @controller.render(component, &block))
    end
  end
end
