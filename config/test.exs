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
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

  config :td_auth, :auth,
    auth_service: TdAuthWeb.ApiServices.MockAuthService,
    protocol: "https",
    domain: "icbluetab.eu.auth0.com",
    audience: nil,
    userinfo: "/userinfo",
    profile_mapping: %{user_name: "nickname",
                       full_name: "name",
                       email:     "email"}

   config :td_auth, TdAuth.Auth.Auth,
     allowed_algos: ["HS512"], # optional
     issuer: "tdauth",
     verify_issuer: false,
     token_ttl: %{"access" => { 12, :hours }, "refresh" => {24, :hours}},
     secret_key: "SuperSecretTruedat"
