# frozen_string_literal: true

require_relative "../test_helper"

module UtilsTests
  class NormalizeHtmlWhitespaceTest < TestCase
    test "collapses multiple spaces down to one" do
      assert_equal(
        " abc def ghi ",
        LiveComponent::Utils.normalize_html_whitespace(" abc  def  ghi  ")
      )
    end

    test "considers newlines and carriage returns to be whitespace" do
      assert_equal(
        " abc def ghi ",
        LiveComponent::Utils.normalize_html_whitespace(" abc\n\ndef\r\n\r\nghi \n")
      )
    end

    test "considers tabs to be whitespace" do
      assert_equal(
        " abc def ghi ",
        LiveComponent::Utils.normalize_html_whitespace(" abc\t\tdef \t \t ghi \t")
      )
    end

    test "considers line feeds and vertical tabs to be whitespace" do
      assert_equal(
        " abc def ghi ",
        LiveComponent::Utils.normalize_html_whitespace(" abc\f\fdef \v \v ghi \f\v")
      )
    end
  end

  class LookupComponentClassTest < TestCase
    class TestComponent < ViewComponent::Base
    end

    class NonTestComponent
    end

    test "finds component classes" do
      assert_equal(
        TestComponent,
        LiveComponent::Utils.lookup_component_class("UtilsTests::LookupComponentClassTest::TestComponent")
      )
    end

    test "raises an error for non-component classes" do
      error = assert_raises(LiveComponent::UnexpectedConstantError) do
        LiveComponent::Utils.lookup_component_class("UtilsTests::LookupComponentClassTest::NonTestComponent")
      end

      assert_equal(
        "cannot find constant 'UtilsTests::LookupComponentClassTest::NonTestComponent' that does not inherit from "\
          "ViewComponent::Base",
        error.message
      )
    end

    test "raises an error when the given constant doesn't exist" do
      error = assert_raises(LiveComponent::UnexpectedConstantError) do
        LiveComponent::Utils.lookup_component_class("IDontExist")
      end

      assert_equal(
        "cannot find constant 'IDontExist' that does not inherit from ViewComponent::Base",
        error.message
      )
    end
  end

  class HtmlParamsForRenderTest < TestCase
    class TestComponent < ViewComponent::Base
      include LiveComponent::Base

      # manually override to simulate having a sidecar .js file
      def self.__lc_controller
        "testcomponent"
      end
    end

    test "returns a rerender target for :parent" do
      assert_equal(
        { "data-rerender-target" => ":parent" },
        LiveComponent::Utils.html_params_for_rerender(:parent)
      )
    end

    test "returns a rerender target for :self" do
      assert_equal(
        { "data-rerender-target" => ":self" },
        LiveComponent::Utils.html_params_for_rerender(:self)
      )
    end

    test "returns a rerender target for the given ID" do
      assert_equal(
        { "data-rerender-id" => "abc123" },
        LiveComponent::Utils.html_params_for_rerender("abc123")
      )
    end

    test "returns a rerender target for the given component class" do
      assert_equal(
        { "data-rerender-target" => "testcomponent" },
        LiveComponent::Utils.html_params_for_rerender(TestComponent)
      )
    end

    test "returns a rerender target for the given component" do
      component = TestComponent.new

      assert_equal(
        { "data-rerender-id" => component.__lc_id },
        LiveComponent::Utils.html_params_for_rerender(component)
      )
    end
  end
end
