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

config :td_auth, :phoenix_swagger,
  swagger_files: %{
   "priv/static/swagger.json" => [router: TdAuthWeb.Router]
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
