defmodule TdAuthWeb.AuthControllerTest do
  use TdAuthWeb.ConnCase

  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all authentication methods", %{conn: conn, swagger_schema: schema} do
      conn = get conn, Routes.auth_path(conn, :index)
      validate_resp_schema(conn, schema, "AuthenticationMethodsResponse")

      %{"oidc" => url, "auth0" => auth0} = json_response(conn, 200)["data"]
      assert String.starts_with?(url, "https://accounts.google.com/o/oauth2")
      assert Map.get(auth0, "clientID") == "CLIENT_ID"
      assert Map.get(auth0, "domain") == "icbluetab.eu.auth0.com"
    end
  end
end
