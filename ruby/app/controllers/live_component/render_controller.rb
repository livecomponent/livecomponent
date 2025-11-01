# frozen_string_literal: true

module LiveComponent
  class RenderController < ActionController::Base
    def show
      render layout: false, formats: [:html]
    end
  end
end
