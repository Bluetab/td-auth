defmodule TdAuthWeb.AuthControllerTest do
  use TdAuthWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all authentication methods", %{conn: conn} do
      conn = get conn, auth_path(conn, :index)
      [%{"url" => url}] = json_response(conn, 200)["data"]
      assert String.starts_with?(url, "https://accounts.google.com/o/oauth2")
    end
  end
end
