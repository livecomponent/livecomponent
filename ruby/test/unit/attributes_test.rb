# frozen_string_literal: true

require_relative "../test_helper"

class AttributesTest < TestCase
  test "renders successfully" do
    render_inline(HelloWorldComponent.new)

    assert_selector "p", text: "Hello, world"
  end

  test "wraps the component in the live-component custom element when no sidecar javascript file" do
    render_inline(HelloWorldComponent.new)

    assert_selector "live-component" do |lc|
      lc.assert_selector "p", text: "Hello, world"
    end
  end

  test "wraps the component in the a custom element named after the component class" do
    render_inline(HelloWorldWithSidecarJsComponent.new)

    assert_selector "lc-helloworldwithsidecarjscomponent" do |lc|
      lc.assert_selector "p", text: "Hello, world"
    end
  end

  test "assigns an ID to the default live-component element" do
    render_inline(HelloWorldComponent.new)

    assert_selector "live-component[data-id]"
  end

  test "assigns an ID to derived custom elements" do
    render_inline(HelloWorldWithSidecarJsComponent.new)

    assert_selector "lc-helloworldwithsidecarjscomponent[data-id]"
  end

  test "uses the default controller name when no sidecar javascript file" do
    render_inline(HelloWorldComponent.new)

    assert_selector "[data-controller=live]"
  end

  test "uses the derived controller name when there is a sidecar javascript file" do
    render_inline(HelloWorldWithSidecarJsComponent.new)

    assert_selector "[data-controller=helloworldwithsidecarjscomponent]"
  end

  test "includes passed attributes in attached state" do
    render_inline(UpdatePropsComponent.new(mode: "foo"))

    state_json = page.find("[data-livecomponent]")["data-state"]
    state = LiveComponent::State.build(JSON.parse(state_json))
    assert_equal "foo", state.props[:mode]
  end

  test "includes slots in attached state" do
    render_inline(AddSlotComponent.new) do |component|
      component.with_item { "Item 1" }
      component.with_item { "Item 2" }
    end

    state_json = page.find("lc-addslotcomponent")["data-state"]
    state = LiveComponent::State.build(JSON.parse(state_json))
    items = state.slots["item"]

    assert_equal 2, items.size

    assert_equal "Item 1", items[0].content
    assert_equal AddSlotComponent::ItemComponent, items[0].klass

    assert_equal "Item 2", items[1].content
    assert_equal AddSlotComponent::ItemComponent, items[1].klass
  end

  test "includes child components in attached state" do
    render_inline(ParentComponent.new)

    state_json = page.find_all("[data-livecomponent]").first["data-state"]
    state = LiveComponent::State.build(JSON.parse(state_json))
    children = state.subs.values

    assert_equal 1, children.size
    assert_equal ParentComponent::ChildComponent, children[0].klass
  end
end
