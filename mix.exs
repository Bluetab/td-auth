defmodule TdAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :td_auth,
      version:
        case System.get_env("APP_VERSION") do
          nil -> "4.32.0-local"
          v -> v
        end,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers() ++ [:phoenix_swagger],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        td_auth: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent],
          steps: [:assemble, &copy_bin_files/1, :tar]
        ]
      ]
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

  defp copy_bin_files(release) do
    File.cp_r("rel/bin", Path.join(release.path, "bin"))
    release
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.1"},
      {:postgrex, "~> 0.15.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.1"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:guardian, "~> 2.0"},
      {:canada, "~> 2.0"},
      {:bcrypt_elixir, "~> 2.0"},
      {:cors_plug, "~> 2.0"},
      {:httpoison, "~> 1.6"},
      {:cabbage,
       git: "https://github.com/Bluetab/cabbage", branch: "feature/background", only: :test},
      {:ex_machina, "~> 2.3", only: :test},
      {:assertions, "~> 0.15", only: :test},
      {:phoenix_swagger, "~> 0.8"},
      {:ex_json_schema, "~> 0.6"},
      {:inflex, "~> 2.0"},
      {:exldap, "~> 0.6"},
      {:openid_connect, "~> 0.2.0"},
      {:esaml, "~> 4.2"},
      # See https://github.com/handnot2/esaml/issues/29
      {:cowboy, "~> 2.7", override: true},
      {:quantum, "~> 3.0"},
      {:td_cache, git: "https://github.com/Bluetab/td-cache.git", tag: "4.31.1"}
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
