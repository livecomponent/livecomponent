# frozen_string_literal: true

class RerenderParentComponent < ViewComponent::Base
  class RerenderChildComponent < ViewComponent::Base
    include LiveComponent::Base
  end

  include LiveComponent::Base

  attr_reader :mode

  def initialize(mode: "start")
    @mode = mode
  end
end
