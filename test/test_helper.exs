{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:guardian)

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(TdAuth.Repo, :manual)
