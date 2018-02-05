use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :td_auth, TdAuthWeb.Endpoint,
  http: [port: 4001],
  server: true

# Hashing algorithm just for testing porpouses
config :td_auth, hashing_module: TdAuth.DummyHashing

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :td_auth, TdAuth.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "td_auth_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
