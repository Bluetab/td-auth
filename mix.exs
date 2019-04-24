defmodule TdAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :td_auth,
      version:
        case System.get_env("APP_VERSION") do
          nil -> "2.17.0-local"
          v -> v
        end,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers() ++ [:phoenix_swagger],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TdAuth.Application, []},
      extra_applications: [:logger, :runtime_tools, :exldap, :esaml]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:jason, "~> 1.0"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.0", runtime: false},
      {:guardian, "~> 1.0"},
      {:canada, "~> 1.0.1"},
      {:comeonin, "~> 4.0"},
      {:bcrypt_elixir, "~> 1.0"},
      {:ex_machina, "~> 2.2.2", only: :test},
      {:cors_plug, "~> 1.2"},
      {:httpoison, "~> 1.0"},
      {:cabbage, git: "https://github.com/Bluetab/cabbage", tag: "v0.3.7-alpha"},
      {:phoenix_swagger, "~> 0.8.0"},
      {:ex_json_schema, "~> 0.5"},
      {:td_perms, git: "https://github.com/Bluetab/td-perms.git", tag: "2.16.2"},
      {:td_hypermedia, git: "https://github.com/Bluetab/td-hypermedia.git", tag: "2.11.0"},
      {:inflex, "~> 1.10.0"},
      {:prometheus_ex, "~> 3.0.2"},
      {:prometheus_plugs, "~> 1.1.5"},
      {:exldap, "~> 0.6"},
      {:openid_connect, "~> 0.2.0"},
      {:esaml, "~> 4.1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
