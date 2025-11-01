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

      super(**options, html: html, &block)
    end

    def button_to(*args, rerender: nil, form: {}, **options, &block)
      if (params = Utils.html_params_for_rerender(rerender))
        form.merge!(params)
      end

      super(*args, **options, form: form, &block)
    end
  end
end
