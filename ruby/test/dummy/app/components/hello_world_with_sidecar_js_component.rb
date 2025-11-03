# frozen_string_literal: true

class HelloWorldWithSidecarJsComponent < ViewComponent::Base
  include LiveComponent::Base

  def call
    content_tag("p") { "Hello, world" }
  end
end
