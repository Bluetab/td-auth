defmodule TdAuth.Auth.Pipeline.Secure do
  @moduledoc false
  use Guardian.Plug.Pipeline,
    otp_app: :td_auth,
    error_handler: TdAuth.Auth.ErrorHandler,
    module: TdAuth.Auth.Guardian

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource, allow_blank: true
  plug Guardian.Plug.EnsureAuthenticated
  plug TdAuth.Auth.Pipeline.CurrentResource
end
