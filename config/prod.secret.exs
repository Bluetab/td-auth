use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :td_auth, TdAuthWeb.Endpoint,
  secret_key_base: "fZFsyAqGLetD8LXb4tbkrHT04TLU8RaNaYyTOZOlw95hybq9zbGsAGsNlLOqlb0+"

# Configure your database
config :td_auth, TdAuth.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "td_auth_prod",
  hostname: "localhost",
  pool_size: 10

config :td_auth, TdAuth.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  token_ttl: %{"access" => { 12, :hours }, "refresh" => {24, :hours}},
  secret_key: "SuperSecretTruedat"

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
