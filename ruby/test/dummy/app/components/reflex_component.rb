# frozen_string_literal: true

class ReflexComponent < ViewComponent::Base
  include LiveComponent::Base

  def initialize(mode: "start")
    @mode = mode
  end

  def change
    @mode = "finish"
  end
end
