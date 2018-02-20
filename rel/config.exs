use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"/2*`P,=O^!o,gn:E>IHwK@?u:}E2`YIEb=|7dH6)WSC;d%jrG*B2QU|RUErF9i69"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"PHpCfQ1{`)2_hNK8~<@YVAuggE$fg<z=.m,_am{IBstH:oA)VrW0,zo]hrU)ZNPT"
  # set pre_start_hook: "rel/hooks/pre-start"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :tdAuth do
  set version: current_version(:td_auth)
  set applications: [
    :runtime_tools
  ]
  set commands: [
    "migrate": "rel/commands/migrate.sh"
  ]
end
