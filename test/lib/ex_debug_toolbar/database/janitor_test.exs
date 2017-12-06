defmodule ExDebugToolbar.Database.JanitorTest do
  use ExDebugToolbar.ChannelCase, async: false

  import ExDebugToolbar.Test.Support.RequestHelpers
  alias ExDebugToolbar.Database.{RequestRepo, Janitor}
  alias ExDebugToolbar.Request

  describe "cleanup_requests/0" do
    setup do
      RequestRepo.purge()
      Application.put_env(:ex_debug_toolbar, :max_requests, 2)
      on_exit fn ->
        Application.put_env(:ex_debug_toolbar, :max_requests, 30)
      end
      for n <- 1..4 do
        pid = spawn fn -> :ok end
        :ok = RequestRepo.insert %Request{pid: pid, uuid: n}
      end
      :ok
    end

    test "pops requests when over configured max number of requests" do
      assert RequestRepo.count() == 4
      Janitor.cleanup_requests()
      assert RequestRepo.count() == 2
      assert {:error, :not_found} = RequestRepo.get(1)
      assert {:error, :not_found} = RequestRepo.get(2)
      assert RequestRepo.all() |> to_uuid == [3, 4]
    end

    test "it broadcasts request:deleted event for each popped requests" do
      @endpoint.subscribe "dashboard:history"
      Janitor.cleanup_requests()
      assert_broadcast "request:deleted", %{uuid: 1}
      assert_broadcast "request:deleted", %{uuid: 2}
    end
  end
end
