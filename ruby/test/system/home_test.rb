# frozen_string_literal: true

require_relative "test_helper"

class HomeTest < ApplicationSystemTestCase
  test "visiting the home page" do
    visit root_path
    assert_selector "h1", text: "Welcome to the Dummy App"
    assert_text "System tests are working!"
  end
end
