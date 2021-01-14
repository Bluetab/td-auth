defmodule TdAuthWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  import TdAuth.Factory
  import TdAuthWeb.Authentication, only: :functions

  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.ConnTest

  using do
    quote do
      # Import conveniences for testing with connections
      import Assertions
      import Plug.Conn
      import Phoenix.ConnTest
      import TdAuth.Factory

      alias TdAuthWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint TdAuthWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(TdAuth.Repo)

    unless tags[:async] do
      Sandbox.mode(TdAuth.Repo, {:shared, self()})
    end

    cond do
      tags[:admin_authenticated] ->
        :user
        |> insert(role: :admin)
        |> create_user_auth_conn()

      tags[:authenticated_user] ->
        :user
        |> insert()
        |> create_user_auth_conn()

      true ->
        {:ok, conn: ConnTest.build_conn()}
    end
  end
end
