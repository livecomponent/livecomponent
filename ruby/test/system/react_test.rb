# frozen_string_literal: true

require_relative "../test_helper"

class ReactTest < ApplicationSystemTestCase
  test "renders a react component" do
    visit components_react_path

    assert_selector "div", text: "Start"
    refute_selector "div", text: "Finish"

    click_button "Finish"

    assert_selector "div", text: "Finish"
    refute_selector "div", text: "Start"
  end
end
