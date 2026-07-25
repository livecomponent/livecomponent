# frozen_string_literal: true

require_relative "../test_helper"

class ControllerNamingTest < TestCase
  test "uses the default controller and tag name when there is no declaration and no sidecar file" do
    assert_empty HelloWorldComponent.__lc_js_sidecar_files
    assert_equal "live", HelloWorldComponent.__lc_controller

    render_inline(HelloWorldComponent.new)

    assert_selector "live-component[data-controller=live]"
  end

  test "derives the controller name from the class name when declared without a name" do
    assert_empty Naming::DerivedComponent.__lc_js_sidecar_files
    assert_equal "naming-derivedcomponent", Naming::DerivedComponent.__lc_controller

    render_inline(Naming::DerivedComponent.new)

    assert_selector "naming-derivedcomponent[data-controller='naming-derivedcomponent']"
  end

  test "derives the controller name from deeply namespaced class names" do
    assert_equal "naming-deeply-nestedcomponent", Naming::Deeply::NestedComponent.__lc_controller

    render_inline(Naming::Deeply::NestedComponent.new)

    assert_selector "naming-deeply-nestedcomponent[data-controller='naming-deeply-nestedcomponent']"
  end

  test "uses an explicitly declared controller name verbatim" do
    assert_equal "my-header", Naming::ExplicitComponent.__lc_controller

    render_inline(Naming::ExplicitComponent.new)

    assert_selector "my-header[data-controller='my-header']"
  end

  test "prefixes single-word controller names when deriving the custom element name" do
    assert_equal "header", Naming::ExplicitSingleWordComponent.__lc_controller

    render_inline(Naming::ExplicitSingleWordComponent.new)

    assert_selector "lc-header[data-controller=header]"
  end

  test "prefers the explicitly declared controller name over the one derived from a sidecar file" do
    refute_empty ExplicitWithSidecarJsComponent.__lc_js_sidecar_files
    assert_equal "explicit-sidecar", ExplicitWithSidecarJsComponent.__lc_controller

    render_inline(ExplicitWithSidecarJsComponent.new)

    assert_selector "explicit-sidecar[data-controller='explicit-sidecar']"
  end
end
