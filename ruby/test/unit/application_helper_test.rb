# frozen_string_literal: true

require_relative "../test_helper"

class ApplicationHelperTest < TestCase
  class ContentTagComponent < ViewComponent::Base
    include LiveComponent::Base

    def call
      content_tag("div", targets: target(:foo), actions: on(:click).call(:foo)) do
        "Hello, world"
      end
    end

    def __lc_controller
      "contenttagcomponent"
    end
  end

  class ButtonToComponent < ViewComponent::Base
    include LiveComponent::Base

    def call
      # this is a dummy path, it can be *any* valid route
      button_to(
        "Foo",
        "/foo",
        targets: target(:foo),
        actions: on(:click).call(:foo),
        rerender: :self,
      )
    end

    def __lc_controller
      "buttontocomponent"
    end
  end

  class FormWithComponent < ViewComponent::Base
    include LiveComponent::Base

    def call
      form_with(
        url: "/foo",
        targets: target(:foo),
        actions: on(:click).call(:foo),
        rerender: :self,
      )
    end

    def __lc_controller
      "formwithcomponent"
    end
  end

  test "content_tag attaches the correct action to the element" do
    render_inline(ContentTagComponent.new)

    assert_selector "[data-action='click->contenttagcomponent#foo']"
  end

  test "content_tag attaches the correct target to the element" do
    render_inline(ContentTagComponent.new)

    assert_selector "[data-contenttagcomponent-target=foo]"
  end

  test "button_to attaches the correct action to the element" do
    render_inline(ButtonToComponent.new)

    assert_selector "button[data-action='click->buttontocomponent#foo']"
  end

  test "button_to attaches the correct target to the element" do
    render_inline(ButtonToComponent.new)

    assert_selector "button[data-buttontocomponent-target=foo]"
  end

  test "button_to attaches the given rerender target" do
    render_inline(ButtonToComponent.new)

    assert_selector "form[data-rerender-target=':self']"
  end

  test "form_with attaches the correct action to the element" do
    render_inline(FormWithComponent.new)

    assert_selector "form[data-action='click->formwithcomponent#foo']"
  end

  test "form_with attaches the correct target to the element" do
    render_inline(FormWithComponent.new)

    assert_selector "form[data-formwithcomponent-target=foo]"
  end

  test "form_with attaches the given rerender target" do
    render_inline(FormWithComponent.new)

    assert_selector "form[data-rerender-target=':self']"
  end
end
