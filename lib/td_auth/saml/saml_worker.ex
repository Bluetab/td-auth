defmodule TdAuth.Saml.SamlWorker do
  @moduledoc """
  GenServer to manage SAML authentication
  """

  use GenServer

  alias TdAuth.Saml

  require Logger
  require Record

  @esaml_lib "esaml/include/esaml.hrl"

  Record.defrecord(:esaml_org, Record.extract(:esaml_org, from_lib: @esaml_lib))
  Record.defrecord(:esaml_contact, Record.extract(:esaml_contact, from_lib: @esaml_lib))
  Record.defrecord(:esaml_sp, Record.extract(:esaml_sp, from_lib: @esaml_lib))

  def start_link(config, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def auth_url(relay_state \\ "") do
    case GenServer.whereis(TdAuth.Saml.SamlWorker) do
      nil -> nil
      _ -> GenServer.call(__MODULE__, {:authn, relay_state})
    end
  end

  def validate(saml_response, saml_encoding \\ nil) do
    GenServer.call(__MODULE__, {:validate, saml_response, saml_encoding})
  end

  def metadata do
    GenServer.call(__MODULE__, {:metadata})
  end

  @impl true
  def init(config) do
    state = load_config(config)
    Logger.info("Started SAML Worker for SP #{config[:sp_id]}")
    {:ok, state}
  end

  @impl true
  def handle_call({:metadata}, _from, %{sp: sp} = state) do
    metadata = Saml.generate_metadata(sp)
    {:reply, metadata, state}
  end

  @impl true
  def handle_call(
        {:validate, saml_response, saml_encoding},
        _from,
        %{
          sp: sp,
          reject_roles: reject_roles,
          allow_groups: allow_groups,
          create_group: create_group
        } = state
      ) do
    reply =
      Saml.decode_and_validate_assertion(
        sp,
        saml_response,
        saml_encoding,
        reject_roles,
        allow_groups,
        create_group
      )

    {:reply, reply, state}
  end

  @impl true
  def handle_call({:authn, relay_state}, _from, %{idp: idp, sp: sp} = state) do
    url = Saml.generate_authn_redirect_url(idp, sp, relay_state)
    {:reply, url, state}
  end

  defp load_config(config) do
    saml_config =
      config
      |> Keyword.drop([
        :sp_key,
        :sp_cert,
        :sp_trusted_fingerprints,
        :reject_roles,
        :allow_groups,
        :sp_idp_signs_envelopes
      ])
      |> Enum.map(fn {k, v} -> {k, to_charlist(v)} end)
      |> Keyword.merge(config, fn _k, v1, _v2 -> v1 end)

    contact =
      esaml_contact(
        name: saml_config[:contact_name],
        email: saml_config[:contact_email]
      )

    org =
      esaml_org(
        name: saml_config[:org_name],
        displayname: saml_config[:org_display_name],
        url: saml_config[:org_url]
      )

    trusted_fingerprints =
      saml_config[:sp_trusted_fingerprints]
      |> String.split(";")
      |> Enum.map(&to_charlist(&1))

    key = :esaml_util.load_private_key(saml_config[:sp_key])

    cert = :esaml_util.load_certificate(saml_config[:sp_cert])

    sp =
      esaml_sp(
        key: key,
        certificate: cert,
        entity_id: saml_config[:sp_id],
        consume_uri: saml_config[:sp_consume_uri],
        metadata_uri: saml_config[:sp_metadata_uri],
        idp_signs_envelopes: saml_config[:sp_idp_signs_envelopes] == "true",
        trusted_fingerprints: trusted_fingerprints,
        org: org,
        tech: contact
      )

    idp = :esaml_util.load_metadata(saml_config[:idp_metadata_url])

    reject_roles =
      saml_config
      |> Keyword.get(:reject_roles, "")
      |> String.split(";")
      |> Enum.map(&to_charlist(&1))

    allow_groups =
      saml_config
      |> Keyword.get(:allow_groups, "")
      |> String.split(";")
      |> Enum.map(&to_charlist(&1))

    create_group = saml_config[:create_group] |> to_string |> String.to_atom

    %{
      sp: :esaml_sp.setup(sp),
      idp: idp,
      reject_roles: reject_roles,
      allow_groups: allow_groups,
      create_group: create_group
    }
  end
end
