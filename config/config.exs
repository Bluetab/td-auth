# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Environment
config :td_auth, :env, Mix.env()

# General application configuration
config :td_auth,
  ecto_repos: [TdAuth.Repo]

config :td_auth, allow_proxy_login: "false"

# Configures the endpoint
config :td_auth, TdAuthWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qf8wPCPHk4ZqqM7ebnfKw2okARcnrqsnfsQjKSGC0AEK87/rkIlXWnYXa5cTZ2TX",
  render_errors: [view: TdAuthWeb.ErrorView, accepts: ~w(json)]

config :td_auth, TdAuth.Repo,
  pool_size: 10

# Configures Elixir's Logger
# set EX_LOGGER_FORMAT environment variable to override Elixir's Logger format
# (without the 'end of line' character)
# EX_LOGGER_FORMAT='$date $time [$level] $message'
config :logger, :console,
  format: (System.get_env("EX_LOGGER_FORMAT") || "$date\T$time\Z [$level]$levelpad $metadata$message") <> "\n",
  level: :info,
  metadata: [:pid, :module],
  utc_log: true

# Configuration for Phoenix
config :phoenix, :json_library, Jason
config :phoenix_swagger, :json_library, Jason

config :td_auth, TdAuth.Auth.Guardian,
  # optional
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  token_ttl: %{"access" => {12, :hours}, "refresh" => {24, :hours}},
  secret_key: "SuperSecretTruedat"

config :td_auth, TdAuth.Auth.Auth0,
  allowed_algos: ["RS256"],
  verify_issuer: true

# ------------ ldap ----------

config :td_auth, eldap_module: :eldap
config :td_auth, exldap_module: Exldap

config :td_auth, :ldap,
  server: "localhost",
  base: "dc=bluetab,dc=net",
  port: "389",
  ssl: "false",
  user_dn: "cn=admin,dc=bluetab,dc=net",
  password: "temporal",
  connection_timeout: "5000",
  profile_mapping: "{\"user_name\":\"cn\",\"full_name\":\"givenName\",\"email\":\"mail\"}",
  bind_pattern: "cn=%{user_name},ou=people,dc=bluetab,dc=net",
  search_path: "ou=people,dc=bluetab,dc=net",
  search_field: "cn",
  validations_file: ""

# ------------ oidc default ----------
config :td_auth, :openid_connect_providers, oidc: []

# --------- Auht0 default --------------
config :td_auth, :auth, auth_service: TdAuthWeb.ApiServices.HttpAuthService

# ------------ ad ----------

config :td_auth, :ad,
  server: "10.0.0.152",
  base: "DC=dns,DC=activedirectory,DC=io",
  port: "389",
  ssl: "false",
  user_dn: "CN=Administrador,CN=Users,DC=dns,DC=activedirectory,DC=io",
  password: "xyzxyz",
  connection_timeout: "5000",
  search_path: "CN=Users,DC=dns,DC=activedirectory,DC=io"

config :td_auth, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [router: TdAuthWeb.Router]
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
