defmodule TdAuth.Saml.SamlWorkerTest do
  use ExUnit.Case, async: true

  alias TdAuth.Saml.SamlWorker

  describe "start_link/2" do
    test "returns nil when worker is not running" do
      assert nil == SamlWorker.auth_url()
    end
  end
end
