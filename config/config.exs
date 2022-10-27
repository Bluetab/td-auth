# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# Environment
config :td_auth, :env, Mix.env()

# General application configuration
config :td_auth,
  ecto_repos: [TdAuth.Repo]

config :td_auth, allow_proxy_login: "false"

# Configures the endpoint
config :td_auth, TdAuthWeb.Endpoint,
  http: [
    port: 4001,
    protocol_options: [
      max_header_value_length: 16_384
    ]
  ],
  url: [host: "localhost"],
  render_errors: [view: TdAuthWeb.ErrorView, accepts: ~w(json)]

config :td_auth, TdAuth.Repo, pool_size: 4

# Configures Elixir's Logger
# set EX_LOGGER_FORMAT environment variable to override Elixir's Logger format
# (without the 'end of line' character)
# EX_LOGGER_FORMAT='$date $time [$level] $message'
config :logger, :console,
  format:
    (System.get_env("EX_LOGGER_FORMAT") || "$date\T$time\Z [$level]$levelpad $metadata$message") <>
      "\n",
  level: :info,
  metadata: [:pid, :module],
  utc_log: true

# Configuration for Phoenix
config :phoenix, :json_library, Jason
config :phoenix_swagger, :json_library, Jason

config :td_cache, :audit,
  service: "td_auth",
  stream: "audit:events"

# Truedat JWT access token and refreh token
# 10 minutes
config :td_auth, TdAuth.Auth.AccessToken, ttl_seconds: 600
# 24 hours
config :td_auth, TdAuth.Auth.RefreshToken, ttl_seconds: 60 * 60 * 24

config :joken,
  default_signer: [
    signer_alg: "HS512",
    key_octet: "SuperSecretTruedat"
  ]

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
  profile_mapping: %{user_name: "cn", full_name: "givenName", email: "mail"},
  bind_pattern: "cn=%{user_name},ou=people,dc=bluetab,dc=net",
  search_path: "ou=people,dc=bluetab,dc=net",
  search_field: "cn"

# ------------ oidc default ----------
config :td_auth, :openid_connect_providers, oidc: []

# --------- Auht0 default --------------
config :td_auth, :auth0,
  auth0_service: TdAuthWeb.ApiServices.HttpAuth0Service,
  profile_mapping: %{user_name: "nickname", full_name: ["name", "family_name"], email: "email"}

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

config :td_auth, TdAuth.Scheduler,
  jobs: [
    [
      schedule: "@reboot",
      task: {TdAuth.Permissions.AclLoader, :load_cache, []},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@hourly",
      task: {TdAuth.Permissions.AclRemover, :delete_stale_acl_entries, []},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@minutely",
      task: {TdAuth.Permissions.RoleLoader, :load_roles, []},
      run_strategy: Quantum.RunStrategy.Local
    ]
  ]

config :td_auth, TdAuthWeb.UserSearchController, max_results: 5

config :td_auth, TdAuthWeb.GroupSearchController, max_results: 5

config :openid_connect, :http_client, TdAuth.HttpClient

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
