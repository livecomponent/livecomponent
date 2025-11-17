# frozen_string_literal: true

class RerenderIdentComponent < ViewComponent::Base
  class RerenderIdentChildComponent < ViewComponent::Base
    include LiveComponent::Base
  end

  include LiveComponent::Base

  attr_reader :mode

  def initialize(mode: "start")
    @mode = mode
  end
end
