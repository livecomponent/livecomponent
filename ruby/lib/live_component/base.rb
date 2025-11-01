# frozen_string_literal: true

require "use_context"

module LiveComponent
  module Base
    JS_SIDECAR_EXTENSIONS = %w(js ts jsx tsx).freeze

    def self.included(base)
      base.prepend(Overrides)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def __lc_js_sidecar_files
        @__lc_js_sidecar_files ||= sidecar_files(JS_SIDECAR_EXTENSIONS)
      end

      def __lc_init_args
        @__lc_init_args ||= instance_method(:initialize).super_method.parameters
      end

      def __lc_compile_if_necessary!
        return if @__lc_compiled

        if registered_slots.empty?
          @__lc_compiled = true
          return
        end

        registered_slots.each do |slot_name, slot_config|
          is_collection = slot_type(slot_name) == :collection
          singular_name = is_collection ? ActiveSupport::Inflector.singularize(slot_name) : slot_name

          __lc_slot_mod.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def with_#{singular_name}(**props, &block)
              new_slot_data = {}
              new_slot_data[:props] = props unless props.empty?

              @__lc[:slots] ||= {}
              @__lc[:slots][#{singular_name.inspect}] ||= []
              @__lc[:slots][#{singular_name.inspect}] << new_slot_data

              singular_name = #{singular_name.inspect}
              slot_def = registered_slots[#{slot_name.inspect}]

              UseContext.provide_context(:__lc_context, { slot_name: singular_name, slot_def: slot_def }) do
                if block
                  super(**props) do |**block_props|
                    slot = block.call(**block_props)

                    if slot.is_a?(ViewComponent::Slot)
                      content = slot.instance_variable_get(:@__vc_content)
                      new_slot_data[:content] = Utils.normalize_html_whitespace(content) if content
                    end

                    if (instance = slot.instance_variable_get(:@__vc_component_instance))
                      if instance.respond_to?(:__lc_attributes)
                        new_slot_data[:props][:__lc_attributes] ||= {}
                        new_slot_data[:props][:__lc_attributes]["data-id"] = instance.__lc_attributes["data-id"]
                      end
                    end

                    slot
                  end
                else
                  super
                end
              end
            end
          RUBY
        end

        unless self < __lc_slot_mod
          prepend(__lc_slot_mod)
        end

        @__lc_compiled = true
      end

      def __lc_slot_mod
        @__lc_slot_mod ||= Module.new
      end

      # For collections
      def __vc_initialize_parameters
        @__vc_initialize_parameters ||= instance_method(:initialize).super_method.parameters
      end

      def __lc_controller
        # If there are any sidecar js files, assume one of them defines a controller
        # named after the Ruby class. Otherwise, use the default LiveController.
        @__lc_controller ||= __lc_js_sidecar_files.empty? ? "live" : self.name.dasherize.downcase.gsub("::", "-")
      end

      def serializes(prop_name, with: nil, **serializer_options, &block)
        if block && with
          raise "Expected `#{__method__}' to be called with a block or the with: parameter, but both were provided"
        end

        if block
          builder = InlineSerializer::Builder.new
          block.call(builder)
          prop_serializers[prop_name] = builder.to_serializer
          return
        end

        unless with
          raise "Expected `#{__method__}' to be called with a block or the with: parameter"
        end

        unless LiveComponent.registered_prop_serializers.include?(with)
          raise "Could not find a serializer with the name '#{with}' - is it registered?"
        end

        prop_serializers[prop_name] = LiveComponent.registered_prop_serializers[with].make(**serializer_options)

        nil
      end

      def prop_serializers
        @prop_serializers ||= {}
      end

      def serialize_props(props)
        {}.tap do |serialized_props|
          props.each_pair do |k, v|
            k = k.to_sym
            serializer = prop_serializers[k] ||= LiveComponent.default_serializer
            serialized_props[k] = serializer.serialize(v)
          end
        end
      end

      def deserialize_props(props)
        {}.tap do |deserialized_props|
          props.each_pair do |k, v|
            k = k.to_sym
            serializer = prop_serializers[k] ||= LiveComponent.default_serializer
            deserialized_props[k] = serializer.deserialize(v)
          end
        end
      end
    end

    module InstanceMethods
      attr_reader :__lc_attributes

      def __lc_id
        @__lc_id ||= @__lc_attributes["data-id"] || SecureRandom.uuid
      end

      def fn(method_name)
        "fn:#{__lc_id}##{method_name}"
      end

      def on(event_name)
        Action.new(__lc_controller, event_name)
      end

      def target(target_name)
        Target.new(__lc_controller, target_name)
      end

      private

      def __lc_tag_name
        @__lc_tag_name ||= if self.class.__lc_js_sidecar_files.empty?
          "live-component"
        else
          self.class.name.gsub("::", "-").downcase.yield_self do |name|
            if name.split("-").size == 1
              "lc-#{name}"  # custom element names have to be more than one word
            else
              name
            end
          end
        end
      end

      def __lc_controller
        self.class.__lc_controller
      end
    end

    module Overrides
      def initialize(__lc_attributes: {}, **props, &block)
        @__lc = { ruby_class: self.class.name }
        @__lc_attributes = __lc_attributes

        UseContext.use_context(:__lc_context, :slot_name) do |slot_name|
          @__lc_slot_name = slot_name if slot_name
        end

        self.class.__lc_compile_if_necessary!

        super(**props, &block)
      end

      def render_in(view_context, &block)
        props = {
          __lc_attributes: @__lc_attributes.merge(
            "data-id" => __lc_id
          )
        }

        current_state = State.new(
          klass: self.class,
          props: props,
          slots: @__lc[:slots] || {},
          subs: @__lc[:subs] || {},
        )

        result = UseContext.use_context(:__lc_context, :state) do |parent_state|
          if !parent_state
            current_state.root!
          end

          if parent_state
            if @__lc_slot_name
              parent_state.slots[@__lc_slot_name] ||= []
              parent_state.slots[@__lc_slot_name] << current_state
            else
              parent_state.subs[__lc_id] = current_state
            end
          end

          UseContext.provide_context(:__lc_context, { state: current_state }) do
            super
          end
        end

        self.class.__lc_init_args.each do |(type, name)|
          if type == :key || type == :keyreq
            props[name] = instance_variable_get(:"@#{name}")
          elsif type == :keyrest
            props.merge!(instance_variable_get(:"@#{name}"))
          end
        end

        if @__vc_content
          @__lc[:content] = Utils.normalize_html_whitespace(@__vc_content)
          current_state.content = @__lc[:content]
        end

        attributes = {
          "data-id" => __lc_id,
          "data-controller" => __lc_controller,
          "data-livecomponent" => "true",
          **@__lc_attributes,
        }

        if current_state.root?
          attributes["data-state"] = current_state.to_json
        end

        if @__lc_slot_name
          attributes["data-slot-name"] = @__lc_slot_name
        end

        content_tag(__lc_tag_name, result, **attributes)
      end
    end
  end
end
