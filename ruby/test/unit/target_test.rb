# frozen_string_literal: true

require_relative "../test_helper"

class TargetTest < TestCase
  test "produces the correct attributes" do
    action = LiveComponent::Target.new("mycontroller", "button")
    assert_equal({ data: { "mycontroller-target": "button" }}, action.to_attributes)
  end
end
