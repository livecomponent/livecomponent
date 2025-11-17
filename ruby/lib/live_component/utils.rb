# frozen_string_literal: true

module LiveComponent
  module Utils
    WHITESPACE_REGEX = /[\f\n\r\t\v ]{2,}/

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

    extend self
  end
end
