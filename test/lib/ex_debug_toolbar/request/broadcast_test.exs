defmodule ExDebugToolbar.Request.BroadcastTest do
  use ExDebugToolbar.ChannelCase, async: true
  alias ExDebugToolbar.Request.Broadcast

  setup :start_request

  describe "request_created/0" do
    setup do
      @endpoint.subscribe("toolbar:request:#{@request_id}")
    end

    test "it broadcasts stopped request" do
      stop_request(@request_id)
      Broadcast.request_created()
      assert_broadcast "request:created", %{id: @request_id}
    end

    test "it does nothing when request is not stopped" do
      Broadcast.request_created()
      refute_broadcast "request:created", %{}
    end

    test "it does nothing when request does not exist" do
      delete_request(@request_id)
      Broadcast.request_created()
      refute_broadcast "request:created", %{}
    end
  end
end