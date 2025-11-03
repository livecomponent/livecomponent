# frozen_string_literal: true

require_relative "../test_helper"

module StateTests
  State = LiveComponent::State

  class BuildTest < TestCase
    test "build allows ruby_class to be unspecified" do
      state = State.build({})
      assert_nil state.klass
    end

    test "build uses empty data structures when not given" do
      state = State.build({})
      assert_equal({}, state.props)
      assert_equal({}, state.slots)
      assert_equal({}, state.subs)
      assert_nil state.content
    end

    test "accepts ruby_class as a string in the state definition" do
      state = State.build({ "ruby_class": "HelloWorldComponent" })
      assert_equal HelloWorldComponent, state.klass
    end

    test "accepts ruby_class as a symbol in the state definition" do
      state = State.build({ ruby_class: "HelloWorldComponent"})
      assert_equal HelloWorldComponent, state.klass
    end

    test "symbolizes prop keys" do
      state = State.build({ ruby_class: UpdatePropsComponent, props: { "mode" => "foo" } })
      assert_equal "foo", state.props[:mode]
    end

    test "deserializes props" do
      state = State.build({
        ruby_class: "SerializerComponent",
        props: {
          symbol: { "_lc_sym" => true, "value" => "custom_value" }
        }
      })

      assert_equal :custom_value, state.props[:symbol]
    end

    test "allows overriding props" do
      state = State.build(
        { ruby_class: UpdatePropsComponent, props: { mode: "foo" } },
        { mode: "bar" }
      )

      assert_equal "bar", state.props[:mode]
    end

    test "disallows looking up components that don't inherit from ViewComponent::Base" do
      error = assert_raises(LiveComponent::UnexpectedConstantError) do
        State.build({ ruby_class: "Object" })
      end

      assert_equal "cannot find constant 'Object' that does not inherit from ViewComponent::Base", error.message
    end
  end

  class RootTest < TestCase
    test "marks the state as root" do
      state = State.build({})
      assert !state.root?
      state.root!
      assert state.root?
    end
  end

  class ToHTest < TestCase
    test "includes the ruby class" do
      state_hash = State.build({ ruby_class: HelloWorldComponent }).to_h
      assert_equal "HelloWorldComponent", state_hash[:ruby_class]
    end

    test "includes props" do
      state_hash = State.build({ ruby_class: UpdatePropsComponent, props: { mode: "foo" }}).to_h
      assert_equal({ mode: "foo" }, state_hash[:props])
    end

    test "includes slots" do
      state_hash =
        State.build({
          ruby_class: AddSlotComponent,
          slots: {
            items: [{
              content: "Item 1"
            }]
          }
        })
        .to_h

      assert_equal(
        {
          items: [{
            ruby_class: nil,
            content: "Item 1",
            props: { "_lc_symkeys" => [] },
            slots: {},
            subs: {},
          }]
        },
        state_hash[:slots]
      )
    end

    test "includes children" do
      state_hash =
        State.build({
          ruby_class: ParentComponent,
          subs: {
            "abc123" => {
              ruby_class: ParentComponent::ChildComponent,
            }
          }
        })
        .to_h

      assert_equal(
        {
          "abc123" => {
            ruby_class: "ParentComponent::ChildComponent",
            content: nil,
            props: {},
            slots: {},
            subs: {},
          }
        },
        state_hash[:subs]
      )
    end
  end

  class ToJsonTest < TestCase
    test "converts to json" do
      state = State.build({ ruby_class: "HelloWorldComponent" })
      assert_equal(
        "{\"ruby_class\":\"HelloWorldComponent\",\"props\":{},\"slots\":{},\"subs\":{},\"content\":null}",
        state.to_json
      )
    end
  end
end
