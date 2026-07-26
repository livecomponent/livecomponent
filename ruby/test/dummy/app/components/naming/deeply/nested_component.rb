# frozen_string_literal: true

module Naming
  module Deeply
    class NestedComponent < ViewComponent::Base
      include LiveComponent::Base

      live_controller

      def call
        content_tag("p") { "Nested" }
      end
    end
  end
end
