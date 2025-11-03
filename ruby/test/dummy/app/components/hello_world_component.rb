# frozen_string_literal: true

class HelloWorldComponent < ViewComponent::Base
  include LiveComponent::Base

  def call
    content_tag("p") { "Hello, world" }
  end
end
