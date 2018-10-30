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
  pubsub: [name: TdAuth.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :td_auth, TdAuth.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  token_ttl: %{"access" => { 12, :hours }, "refresh" => {24, :hours}},
  secret_key: "SuperSecretTruedat"

# --------- Auht0 --------------

config :td_auth, :auth,
  auth_service: TdAuthWeb.ApiServices.HttpAuthService,
  protocol: "https",
  domain: "icbluetab.eu.auth0.com",
  audience: "https://td.bluetab.net",
  userinfo: "/userinfo",
  profile_mapping: %{user_name: "nickname",
                     full_name: "name",
                     email:     "email"}


 config :td_auth, TdAuth.Auth.Auth,
   allowed_algos: ["RS256"],
   issuer: "https://icbluetab.eu.auth0.com/",
   verify_issuer: true,
   secret_key:
    %{
       "alg" => "RS256",
       "kty" => "RSA",
       "use" => "sig",
       "x5c" => [
         "MIIDBzCCAe+gAwIBAgIJNvyOA2AdsSSkMA0GCSqGSIb3DQEBCwUAMCExHzAdBgNVBAMTFmljYmx1ZXRhYi5ldS5hdXRoMC5jb20wHhcNMTgwNTAzMDkxNzU4WhcNMzIwMTEwMDkxNzU4WjAhMR8wHQYDVQQDExZpY2JsdWV0YWIuZXUuYXV0aDAuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAx/x1/xfYOD65ct3WvaGDhO+lCxXTlAFU0ynIMv3l1I3ueXEMS4RaOa3A01yb4MxjMDV33kSZ5rUqimtGlMY7AiHmudCYBOND7bvByor6UbD8pkTgxKtttCfIf36wsFvZpTR+8HjFXe/Dl2qp8kQUDaQzYxftOoAD8e5X56RMYYP+oZM9R8mY6149QYehieUPH5u4HP3YXJNKLoovtn2OVg+E4rgbCAUNHXlHMA5VXiJ1DoJuDiYF6iFrmIkVIZgqdAKCo+DwvJ0ii1DIIfDd+AuPAshBDBFe0Hne4Q9bGJwfdHifkUw9ailJUhN8kiHNqd/GHn4/uxvasHDiKws8YQIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBRWzpKkYyy73BD4y0ku/X44eT938DAOBgNVHQ8BAf8EBAMCAoQwDQYJKoZIhvcNAQELBQADggEBAKzk+NsAafwbZj4OPXebOI2TAmz5KOWf2RN449ITbXBa/y/q8WiMdCmvwOqky3Szc7jmpWNNx8zecCPAVMIu9h3c+8LjGIH3I1VLpjt9CUDj1fUtQWAnzmGz8YByYNvio4l8fDVCQ8dNjAoMJDhcoTusGDj9Yuoj1CMIpX5nqMcPhvfU8KUTPlIuovB+MUu+SFRCXph2Ro7kwWxk4mZW9L0l97pdj52HkcegqKFQO1rVxvDjXYLU/rinvq+1Ms+/4L4kG27bU1ulzkO05fVrICL/HlSGNd02NwYPx04bqBxYF2CzYP2R1VZSyh+tC7iqbdRv+Y5IaFFGXb6G1aZ8EFw="
       ],
       "n" => "x_x1_xfYOD65ct3WvaGDhO-lCxXTlAFU0ynIMv3l1I3ueXEMS4RaOa3A01yb4MxjMDV33kSZ5rUqimtGlMY7AiHmudCYBOND7bvByor6UbD8pkTgxKtttCfIf36wsFvZpTR-8HjFXe_Dl2qp8kQUDaQzYxftOoAD8e5X56RMYYP-oZM9R8mY6149QYehieUPH5u4HP3YXJNKLoovtn2OVg-E4rgbCAUNHXlHMA5VXiJ1DoJuDiYF6iFrmIkVIZgqdAKCo-DwvJ0ii1DIIfDd-AuPAshBDBFe0Hne4Q9bGJwfdHifkUw9ailJUhN8kiHNqd_GHn4_uxvasHDiKws8YQ",
       "e" => "AQAB",
       "kid" => "NzM4Q0M3RUM4MjRBMkQyNTkzRTgyN0MwQTA3MjI0ODQwODM3Q0RDMA",
       "x5t" => "NzM4Q0M3RUM4MjRBMkQyNTkzRTgyN0MwQTA3MjI0ODQwODM3Q0RDMA"
 }

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

config :td_perms, permissions: [
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
  :manage_confidential_business_concepts
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
