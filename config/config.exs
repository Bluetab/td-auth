# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :td_auth,
  ecto_repos: [TdAuth.Repo]

# Hashing algorithm
config :td_auth, hashing_module: Comeonin.Bcrypt

# Configures the endpoint
config :td_auth, TdAuthWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qf8wPCPHk4ZqqM7ebnfKw2okARcnrqsnfsQjKSGC0AEK87/rkIlXWnYXa5cTZ2TX",
  render_errors: [view: TdAuthWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: TdAuth.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :td_auth, TdAuth.Auth.Guardian,
  # optional
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  token_ttl: %{"access" => {12, :hours}, "refresh" => {24, :hours}},
  secret_key: "SuperSecretTruedat"

# ------------ ldap ----------

config :td_auth, :ldap,
  server: "localhost",
  base: "dc=bluetab,dc=net",
  port: "389",
  ssl: "false",
  user_dn: "cn=admin,dc=bluetab,dc=net",
  password: "temporal",
  connection_timeout: "5000",
  profile_mapping: "{\"user_name\":\"cn\",\"full_name\":\"cn\",\"email\":\"cn\"}",
  bind_pattern: "cn=%{user_name},ou=people,dc=bluetab,dc=net",
  search_path: "ou=people,dc=bluetab,dc=net",
  search_field: "cn"

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

config :td_auth, cache_users_on_startup: true
config :td_auth, cache_acl_on_startup: true
config :td_auth, acl_removement: true
config :td_auth, acl_removement_frequency: 36_00_000

config :td_perms,
  permissions: [
    :is_admin,
    :create_acl_entry,
    :update_acl_entry,
    :delete_acl_entry,
    :create_domain,
    :update_domain,
    :delete_domain,
    :view_domain,
    :create_business_concept,
    :create_data_structure,
    :update_business_concept,
    :update_data_structure,
    :send_business_concept_for_approval,
    :delete_business_concept,
    :delete_data_structure,
    :publish_business_concept,
    :reject_business_concept,
    :deprecate_business_concept,
    :manage_business_concept_alias,
    :view_data_structure,
    :view_draft_business_concepts,
    :view_approval_pending_business_concepts,
    :view_published_business_concepts,
    :view_versioned_business_concepts,
    :view_rejected_business_concepts,
    :view_deprecated_business_concepts,
    :manage_business_concept_links,
    :manage_quality_rule,
    :manage_confidential_business_concepts,
    :create_ingest,
    :update_ingest,
    :send_ingest_for_approval,
    :delete_ingest,
    :publish_ingest,
    :reject_ingest,
    :deprecate_ingest,
    :view_draft_ingests,
    :view_approval_pending_ingests,
    :view_published_ingests,
    :view_versioned_ingests,
    :view_rejected_ingests,
    :view_deprecated_ingests,
    :manage_confidential_structures
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
