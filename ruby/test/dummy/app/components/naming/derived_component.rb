# frozen_string_literal: true

module Naming
  class DerivedComponent < ViewComponent::Base
    include LiveComponent::Base

    live_controller

    def call
      content_tag("p") { "Derived" }
    end
  end
end
