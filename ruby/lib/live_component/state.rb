# frozen_string_literal: true

module LiveComponent
  class State
    class << self
      def build(definition, prop_overrides = {})
        klass = definition["ruby_class"] || definition[:ruby_class]
        klass = LiveComponent::Utils.lookup_component_class(klass) if klass && !klass.is_a?(Class)
        props = definition["props"] || definition[:props] || {}

        props.symbolize_keys!
        props.except!(*prop_overrides.keys)
        props = klass.deserialize_props(props) if klass
        props.merge!(prop_overrides)

        slots = build_slots(definition["slots"] || definition[:slots] || {}) || {}
        subs = build_subs(definition["subs"] || definition[:subs] || {}) || {}

        State.new(
          klass: klass,
          props: props,
          slots: slots,
          subs: subs,
          content: definition["content"] || definition[:content]
        )
      end

      private

      def build_slots(slot_map)
        return unless slot_map

        {}.tap do |results|
          slot_map.each do |slot_name, slot_entries|
            results[slot_name] = slot_entries.map do |slot_entry|
              build(slot_entry)
            end
          end
        end
      end

      def build_subs(sub_map)
        return unless sub_map

        sub_map.each_with_object({}) do |(sub_id, sub_entry), memo|
          memo[sub_id] = build(sub_entry)
        end
      end
    end

    attr_reader :root, :klass, :props, :slots, :subs
    attr_accessor :content

    alias root? root

    def initialize(root: false, klass: nil, props: {}, slots: {}, subs: {}, content: nil)
      @root = root
      @klass = klass
      @props = props
      @slots = slots
      @subs = subs
      @content = content
    end

    def root!
      @root = true
    end

    def to_h
      {
        ruby_class: klass ? klass.name : nil,

        props: klass ? klass.serialize_props(props) : LiveComponent.serializer.serialize(props),

        slots: slots.each_with_object({}) do |(k, v), h|
          h[k] = v.map(&:to_h)
        end,

        subs: subs.each_with_object({}) do |(k, v), h|
          h[k] = v.to_h
        end,

        content: content,
      }
    end

    def to_json
      to_h.to_json
    end
  end
end
