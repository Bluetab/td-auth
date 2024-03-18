import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :td_auth, TdAuthWeb.Endpoint,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :td_auth, TdAuth.Repo,
  username: "postgres",
  password: "postgres",
  database: "td_auth_dev",
  hostname: "postgres"

# Redis configuration
config :td_cache, redis_host: "redis"

# Truedat JWT access token and refreh token for dev
# 24h
config :td_auth, TdAuth.Auth.AccessToken, ttl_seconds: 60 * 60 * 24
# 30 days
config :td_auth, TdAuth.Auth.RefreshToken, ttl_seconds: 60 * 60 * 24 * 30
