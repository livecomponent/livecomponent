# frozen_string_literal: true

require_relative "../test_helper"

class RenderTest < ApplicationSystemTestCase
  test "adds a new slot and re-renders" do
    visit components_add_slot_path

    assert_selector "ul li", text: "Item 1"
    assert_selector "ul li", text: "Item 2"
    refute_selector "ul li", text: "Item 3"

    click_button "Add"

    assert_selector "ul li", text: "Item 3"
  end

  test "updates props and re-renders" do
    visit components_update_props_path
    assert_selector "p", text: "Start"

    click_button "Finish"

    assert_selector "p", text: "Changed"
  end

  test "can re-render self on form submission" do
    visit components_rerender_self_path
    assert_selector "p", text: "Start"

    click_button "Save"

    assert_selector "p", text: "Changed"
  end

  test "can re-render parent on form submission" do
    visit components_rerender_parent_path
    assert_selector "p", text: "Start"

    click_button "Save"

    assert_selector "p", text: "Changed"
  end

  test "can re-render an identifier (component class) on form submission" do
    visit components_rerender_ident_path
    assert_selector "p", text: "Start"

    click_button "Save"

    assert_selector "p", text: "Changed"
  end

  test "can re-render an id on form submission" do
    visit components_rerender_id_path
    assert_selector "p", text: "Start"

    click_button "Save"

    assert_selector "p", text: "Changed"
  end

  test "allows calling methods on components, i.e. allows reflexes" do
    visit components_reflex_path

    assert_selector "p", text: "Start"

    click_button "Change"

    assert_selector "p", text: "Changed"
  end
end
