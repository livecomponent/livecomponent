# frozen_string_literal: true

require_relative "../test_helper"

class RecordProxyTest < TestCase
  setup do
    @todo_list = TodoList.create(name: "Groceries")
    @todo_item = @todo_list.todo_items.create(text: "Broccoli")
  end

  test "does not load the record when accessing the id attribute" do
    proxy = LiveComponent::RecordProxy.for(@todo_item.to_global_id)

    assert_no_queries do
      assert_equal @todo_item.id, proxy.id
    end
  end

  test "does not load the record when accessing cached attributes" do
    proxy = LiveComponent::RecordProxy.for(@todo_item.to_global_id, { "text" => @todo_item.text })

    assert_no_queries do
      assert_equal @todo_item.text, proxy.text
    end
  end

  test "loads the record when accessing uncached attributes" do
    proxy = LiveComponent::RecordProxy.for(@todo_item.to_global_id, { "text" => @todo_item.text })

    assert_queries_count(1) do
      assert_equal @todo_item.todo_list_id, proxy.todo_list_id
    end
  end

  test "proxies methods to the record" do
    proxy = LiveComponent::RecordProxy.for(@todo_item.to_global_id)

    assert_queries_count(1) do
      assert_equal "broccoli", proxy.lowercase_text
    end
  end

  test "#load only queries once" do
    proxy = LiveComponent::RecordProxy.for(@todo_item.to_global_id)
    assert_queries_count(1) { proxy.load }
    assert_no_queries { proxy.load }
  end

  test "#reload queries every time" do
    proxy = LiveComponent::RecordProxy.for(@todo_item.to_global_id)
    assert_queries_count(1) { proxy.reload }
    assert_queries_count(1) { proxy.reload }
  end

  test "#reload picks up changes" do
    proxy = LiveComponent::RecordProxy.for(@todo_item.to_global_id)
    assert_equal "Broccoli", proxy.text

    @todo_item.update(text: "Fennel")
    assert_equal "Broccoli", proxy.text

    proxy.reload
    assert_equal "Fennel", proxy.text
  end

  test "#to_global_id returns a copy of the same GID the proxy was initialized with" do
    gid = @todo_item.to_global_id
    proxy = LiveComponent::RecordProxy.for(gid)
    assert_equal gid, proxy.to_global_id
    assert_not_equal gid.object_id, proxy.to_global_id.object_id
  end

  test "#to_signed_global_id returns a signed copy of the same GID the proxy was initialized with" do
    gid = @todo_item.to_global_id
    proxy = LiveComponent::RecordProxy.for(gid)
    assert_equal gid, proxy.to_signed_global_id
    assert_not_equal gid.object_id, proxy.to_signed_global_id.object_id
  end

  test "#to_model returns itself" do
    proxy = LiveComponent::RecordProxy.for(@todo_item.to_global_id)
    assert_equal proxy, proxy.to_model
  end

  test "#to_param returns the record's ID as a string" do
    proxy = LiveComponent::RecordProxy.for(@todo_item.to_global_id)
    assert_equal @todo_item.id.to_s, proxy.to_param
  end
end
