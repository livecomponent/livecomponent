# frozen_string_literal: true

module LiveComponent
  module Utils
    WHITESPACE_REGEX = /[\f\n\r\t\v ]{2,}/
    PLURAL_DATA_ATTRIBUTES = %i[action target].freeze

    def normalize_html_whitespace(str)
      str.gsub(WHITESPACE_REGEX, " ")
    end

    def lookup_component_class(const_str)
      const = safe_lookup_component_class(const_str)
      return const if const

      raise UnexpectedConstantError,
        "cannot find constant '#{const_str}' that does not inherit from ViewComponent::Base"
    end

    def safe_lookup_component_class(const_str)
      const = const_str.safe_constantize

      if const && const < ::ViewComponent::Base
        const
      end
    end

    def html_params_for_rerender(object)
      case object
      when :self, :parent
        return { "data-rerender-target" => ":#{object}" }
      when Symbol
        const = safe_lookup_component_class(object.to_s)
        return({ "data-rerender-target" => const.name }) if const

        raise UnexpectedConstantError, "cannot find constant '#{object}' to use as a rerender target"
      when String
        return { "data-rerender-id" => object }
      when Class
        if object < LiveComponent::Base
          return { "data-rerender-target" => object.name }
        end
      else
        if object.respond_to?(:__lc_id)
          return { "data-rerender-id" => object.__lc_id }
        end
      end

      nil
    end

    def translate_all_attrs(kwargs)
      kwargs = kwargs.reject do |_, v|
        v.is_a?(String) && v.start_with?("fn:")
      end

      # TODO: allow folks to add their own attr classes?
      [Action, Target].inject(kwargs) do |memo, attr_klass|
        if kwargs.include?(attr_klass.attr_name)
          translate_attrs(attr_klass, memo)
        else
          memo
        end
      end
    end

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

    extend self
  end
end
