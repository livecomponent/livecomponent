# frozen_string_literal: true

class ParentComponent < ViewComponent::Base
  class ChildComponent < ViewComponent::Base
    include LiveComponent::Base

    def call
      "Child content".html_safe
    end
  end

  include LiveComponent::Base
end
