# frozen_string_literal: true

module LiveComponent
  module ApplicationHelper
    def live
      @__lc_tag_builder ||= LiveComponent::TagBuilder.new(self)
    end

    def form_with(rerender: nil, html: {}, **options, &block)
      if (params = Utils.html_params_for_rerender(rerender))
        html.merge!(params)
      end

      options = ::LiveComponent::Utils.translate_all_attrs(options)

      super(**options, html: html, &block)
    end

    def button_to(*args, rerender: nil, form: {}, **options, &block)
      if (params = Utils.html_params_for_rerender(rerender))
        form.merge!(params)
      end

      options = ::LiveComponent::Utils.translate_all_attrs(options)

      super(*args, **options, form: form, &block)
    end

    def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
      if block_given?
        options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
      end

      options ||= {}
      options = ::LiveComponent::Utils.translate_all_attrs(options)

      super
    end
  end
end
