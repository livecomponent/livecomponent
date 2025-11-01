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

        kwargs = ViewComponentUtils.translate_attrs(Action, kwargs) if kwargs[:actions]
        kwargs = ViewComponentUtils.translate_attrs(Target, kwargs) if kwargs[:targets]

        super
      end
    end
  end

  module ViewComponentUtils
    PLURAL_DATA_ATTRIBUTES = %i[action target].freeze

    class << self
      def translate_attrs(attr_klass, kwargs)
        if kwargs[attr_klass.attr_name].is_a?(Array)
          return kwargs unless kwargs[attr_klass.attr_name].all? { |action| action.is_a?(attr_klass) }
        else
          return kwargs unless kwargs[attr_klass.attr_name].is_a?(attr_klass)
        end

        attrs = Array(kwargs.delete(attr_klass.attr_name))

        attrs.each do |attr|
          kwargs[:data] = merge_data(kwargs, attr.to_attributes)
        end

        kwargs
      end

      # Borrowed from primer_view_components
      # See: https://github.com/primer/view_components/blob/b0acdfffaa30e606a07db657d9b444b4de8ca860/app/lib/primer/attributes_helper.rb
      #
      # Merges hashes that contain "data-*" keys and nested data: hashes. Removes keys from
      # each hash and returns them in the new hash.
      #
      # Eg. merge_data({ "data-foo": "true" }, { data: { bar: "true" } })
      #     => { foo: "true", bar: "true" }
      #
      # Certain data attributes can contain multiple values separated by spaces. merge_data
      # will combine these plural attributes into a composite string.
      #
      # Eg. merge_data({ "data-target": "foo" }, { data: { target: "bar" } })
      #     => { target: "foo bar" }
      def merge_data(*hashes)
        merge_prefixed_attribute_hashes(
          *hashes, prefix: :data, plural_keys: PLURAL_DATA_ATTRIBUTES
        )
      end

      private

      def merge_prefixed_attribute_hashes(*hashes, prefix:, plural_keys:)
        {}.tap do |result|
          hashes.each do |hash|
            next unless hash

            prefix_hash = hash.delete(prefix) || {}

            prefix_hash.each_pair do |key, val|
              result[key] =
                if plural_keys.include?(key)
                  [*(result[key] || "").split, val].join(" ").strip
                else
                  val
                end
            end

            hash.delete_if do |key, val|
              key_s = key.to_s

              if key.start_with?("#{prefix}-")
                bare_key = key_s.sub("#{prefix}-", "").to_sym

                result[bare_key] =
                  if plural_keys.include?(bare_key)
                    [*(result[bare_key] || "").split, val].join(" ").strip
                  else
                    val
                  end

                true
              else
                false
              end
            end
          end
        end
      end
    end
  end
end
