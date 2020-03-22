use Mix.Config

# For production, we often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# TdAuthWeb.Endpoint.init/2 when load_from_system_env is
# true. Any dynamic configuration should be done there.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# This is an API, so we don't cache a static manifest.
config :td_auth, TdAuthWeb.Endpoint,
  http: [port: 4001],
  server: true,
  version: Mix.Project.config()[:version]
