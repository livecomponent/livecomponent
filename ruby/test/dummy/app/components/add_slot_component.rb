# frozen_string_literal: true

class AddSlotComponent < ViewComponent::Base
  class ItemComponent < ViewComponent::Base
    include LiveComponent::Base
  end

  include LiveComponent::Base

  renders_many :items, ItemComponent
end
