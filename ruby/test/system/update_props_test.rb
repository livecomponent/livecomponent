# frozen_string_literal: true

require_relative "test_helper"

class HomeTest < ApplicationSystemTestCase
  test "updates props and re-renders" do
    visit components_update_props_path
    assert_selector "p", text: "Start"

    click_button "Finish"

    assert_selector "p", text: "Changed"
  end
end
