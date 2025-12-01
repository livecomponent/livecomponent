# frozen_string_literal: true

require_relative "../test_helper"

class ActionTest < TestCase
  test "produces the correct attributes" do
    action = LiveComponent::Action.new("mycontroller", "click").call("button_clicked")
    assert_equal({ "data-action": "click->mycontroller#button_clicked" }, action.to_attributes)
  end
end
