use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :td_auth, TdAuthWeb.Endpoint,
  http: [port: 4001],
  server: true

# Configure your database
config :td_auth, TdAuth.Repo,
  username: "postgres",
  password: "postgres",
  database: "td_auth_test",
  hostname: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

config :td_auth, :auth,
  auth_service: TdAuthWeb.ApiServices.MockAuthService,
  protocol: "https",
  domain: "icbluetab.eu.auth0.com",
  client_id: "CLIENT_ID",
  audience: nil,
  userinfo: "/userinfo",
  profile_mapping: %{user_name: "nickname", full_name: ["name", "family_name"], email: "email"}

# Redis configuration
config :td_cache, redis_host: "redis"

config :td_auth, :openid_connect_providers,
  oidc: [
    discovery_document_uri: "https://accounts.google.com/.well-known/openid-configuration",
    client_id: "CLIENT_ID",
    client_secret: "CLIENT_SECRET",
    redirect_uri: "http://localhost:8080",
    scope: "openid profile",
    response_type: "id_token"
  ]

config :td_auth, eldap_module: TdAuth.Ldap.EldapMock
config :td_auth, exldap_module: TdAuth.Ldap.EldapMock

config :bcrypt_elixir, log_rounds: 4

# Print only warnings and errors during test
config :logger, level: :warn
