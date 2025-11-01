# frozen_string_literal: true

module LiveComponent
  class RenderComponent < ViewComponent::Base
    def initialize(state, reflexes, prop_overrides = {})
      @state = LiveComponent::State.build(state, prop_overrides)
      @reflexes = reflexes
    end

    def render_in(view_context, &block)
      component = @state.klass.new(**@state.props.symbolize_keys)

      @reflexes.each do |reflex|
        method_name = reflex["method_name"] || reflex[:method_name]

        props = (reflex["props"] || reflex[:props] || {}).each_with_object({}) do |(k, v), memo|
          memo[k.to_sym] = LiveComponent.default_serializer.deserialize(v)
        end

        SafeDispatcher.send_safely(component, method_name, **props)
      end

      component.render_in(view_context) do
        apply_slots(component, @state.slots)
        block.call(component) if block
        @state.content
      end
    end

    private

    def apply_slots(component_instance, slots)
      slots.each do |slot_method, slot_defs|
        slot_defs.each do |slot_def|
          component_instance.send("with_#{slot_method}", **slot_def.props) do |slot_instance|
            apply_slots(slot_instance, slot_def.slots)
            slot_def.content
          end
        end
      end
    end
  end
end
