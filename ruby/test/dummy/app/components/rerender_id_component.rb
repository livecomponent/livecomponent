# frozen_string_literal: true

class RerenderIdComponent < ViewComponent::Base
  class RerenderIdChildComponent < ViewComponent::Base
    include LiveComponent::Base

    def initialize(parent_id:)
      @parent_id = parent_id
    end
  end

  include LiveComponent::Base

  attr_reader :mode

  def initialize(mode: "start")
    @mode = mode
  end
end
