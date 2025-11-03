# frozen_string_literal: true

class SerializerComponent < ViewComponent::Base
  include LiveComponent::Base

  attr_reader :symbol

  def initialize(symbol: :default_symbol_value)
    @symbol = symbol
  end
end
