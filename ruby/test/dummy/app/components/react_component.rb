# frozen_string_literal: true

class ReactComponent < ViewComponent::Base
  include LiveComponent::Base

  attr_reader :mode

  def initialize(mode: "start")
    @mode = mode
  end
end
