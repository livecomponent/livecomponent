# frozen_string_literal: true

module Naming
  class ExplicitComponent < ViewComponent::Base
    include LiveComponent::Base

    live_controller "my-header"

    def call
      content_tag("p") { "Explicit" }
    end
  end
end
