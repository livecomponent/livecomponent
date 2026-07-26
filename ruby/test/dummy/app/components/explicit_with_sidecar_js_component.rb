# frozen_string_literal: true

class ExplicitWithSidecarJsComponent < ViewComponent::Base
  include LiveComponent::Base

  live_controller "explicit-sidecar"

  def call
    content_tag("p") { "Explicit with sidecar" }
  end
end
