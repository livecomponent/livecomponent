# frozen_string_literal: true

require_relative "../test_helper"

class SafeDispatcherTest < TestCase
  class TestComponent < ViewComponent::Base
    def public_method
      "Hey there, I'm public!"
    end

    private

    def private_method
      "Shhh, I'm private"
    end
  end

  class TestNonComponent
    def public_method
      "Hey there, I'm not a component!"
    end
  end

  test "allows calling public methods on component instances" do
    assert_equal(
      "Hey there, I'm public!",
      LiveComponent::SafeDispatcher.send_safely(TestComponent.new, :public_method)
    )
  end

  test "disallows calling private methods" do
    error = assert_raises(LiveComponent::SafeDispatchError) do
      LiveComponent::SafeDispatcher.send_safely(TestComponent.new, :private_method)
    end

    assert_equal(
      "`private_method' could not be called on an object of type 'SafeDispatcherTest::TestComponent'. "\
        "Only public methods defined on classes that inherit from ViewComponent::Base "\
        "may be called.",
      error.message
    )
  end

  test "disallows calling methods on non-component instances" do
    error = assert_raises(LiveComponent::SafeDispatchError) do
      LiveComponent::SafeDispatcher.send_safely(TestNonComponent.new, :public_method)
    end

    assert_equal(
      "`public_method' could not be called on an object of type 'SafeDispatcherTest::TestNonComponent'. "\
        "Only public methods defined on classes that inherit from ViewComponent::Base "\
        "may be called.",
      error.message
    )
  end

  test "disallows calling non-existent methods" do
    error = assert_raises(LiveComponent::SafeDispatchError) do
      LiveComponent::SafeDispatcher.send_safely(TestComponent.new, :non_existent_method)
    end

    assert_equal(
      "`non_existent_method' could not be called on an object of type 'SafeDispatcherTest::TestComponent'. "\
        "Only public methods defined on classes that inherit from ViewComponent::Base "\
        "may be called.",
      error.message
    )
  end
end
