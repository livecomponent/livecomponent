# frozen_string_literal: true

module Naming
  class ExplicitSingleWordComponent < ViewComponent::Base
    include LiveComponent::Base

    live_controller "header"

    def call
      content_tag("p") { "Explicit single word" }
    end
  end
end
