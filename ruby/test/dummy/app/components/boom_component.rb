# frozen_string_literal: true

class BoomComponent < ViewComponent::Base
  include LiveComponent::Base

  def call
    raise "boom"
  end
end
