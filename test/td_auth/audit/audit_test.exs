defmodule TdAuth.Audit.AuditTest do

  use TdAuth.DataCase

  alias TdAuth.AuditAuth.Audit
  alias TdCache.Redix
  alias TdCache.Redix.Stream

  @stream TdCache.Audit.stream()

  setup_all do
    Redix.del!(@stream)
    :ok
  end

  setup do
    on_exit(fn -> Redix.del!(@stream) end)
  end

  describe " attempt_event/2 " do
    test "publishes an attempt event" do
      assert {:ok, event_id} = Audit.login_attempt("foo", "someelse")
      assert {:ok, [event]} = Stream.range(:redix, @stream, event_id, event_id, transform: :range)

      assert %{
        event: "login_attempt",
        payload: payload,
        resource_id: "",
        resource_type: "auth",
        service: "td_auth",
        ts: _ts,
        user_id: ""
      } = event

      assert %{
         "access_method" => "foo",
         "user_name" => "someelse",
       } = Jason.decode!(payload)
    end
  end

  describe "session_event/2" do
    test "publishes an login success event" do

      user = %{id: "1",  user_name: "someelse"}
      user_id = user.id
      assert {:ok, event_id} = Audit.login_success("foo", user)
      assert {:ok, [event]} = Stream.range(:redix, @stream, event_id, event_id, transform: :range)

      assert %{
              event: "login_success",
              payload: payload,
              resource_id: ^user_id,
              resource_type: "auth",
              service: "td_auth",
              ts: _ts,
              user_id: ^user_id
            } = event

      assert %{
         "access_method" => "foo",
         "user_name" => "someelse",
       } = Jason.decode!(payload)
     end
  end
end
