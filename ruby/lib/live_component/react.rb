# frozen_string_literal: true

module LiveComponent
  class React < ViewComponent::Base
    include LiveComponent::Base

    def initialize(component:, **props)
      @component = component
      @props = props
    end

    def call
      ""
    end

    def __lc_tag_name
      "live-component-react"
    end

    def __lc_controller
      "livereact"
    end
  end
end
