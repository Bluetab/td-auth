defmodule TdAuth.Auth.RefreshTokenTest do
  use ExUnit.Case

  alias TdAuth.Auth.RefreshToken

  describe "RefreshToken.encode_and_sign/2" do
    test "generates a verifiable and validatable signed token" do
      assert {:ok, %{} = claims} = RefreshToken.generate_claims(%{"sub" => "subsub"})

      assert %{
               "aud" => "tdauth",
               "exp" => exp,
               "sub" => "subsub",
               "iat" => iat,
               "iss" => "tdauth",
               "jti" => _,
               "nbf" => nbf
             } = claims

      assert {:ok, jwt, ^claims} = RefreshToken.encode_and_sign(claims)
      assert {:ok, ^claims} = RefreshToken.verify(jwt)
      assert {:ok, ^claims} = RefreshToken.validate(claims)
      assert exp == iat + 86_400
      assert nbf == iat
    end
  end
end
