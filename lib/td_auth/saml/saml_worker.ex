defmodule TdAuth.Saml.SamlWorker do
  @moduledoc """
  GenServer to manage SAML authentication
  """

  use GenServer

  require Logger
  require Record

  @esaml_lib "esaml/include/esaml.hrl"

  Record.defrecord(:esaml_org, Record.extract(:esaml_org, from_lib: @esaml_lib))
  Record.defrecord(:esaml_contact, Record.extract(:esaml_contact, from_lib: @esaml_lib))
  Record.defrecord(:esaml_sp, Record.extract(:esaml_sp, from_lib: @esaml_lib))
  Record.defrecord(:esaml_idp_metadata, Record.extract(:esaml_idp_metadata, from_lib: @esaml_lib))
  Record.defrecord(:esaml_assertion, Record.extract(:esaml_assertion, from_lib: @esaml_lib))
  Record.defrecord(:esaml_subject, Record.extract(:esaml_subject, from_lib: @esaml_lib))

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
    metadata =
      sp
      |> :esaml_sp.generate_metadata()
      |> (fn x -> [x] end).()
      |> :xmerl.export(:xmerl_xml)
      |> List.flatten()

    {:reply, metadata, state}
  end

  @impl true
  def handle_call({:validate, saml_response, saml_encoding}, _from, %{sp: sp} = state) do
    xml = :esaml_binding.decode_response(saml_encoding, saml_response)

    reply =
      case :esaml_sp.validate_assertion(xml, sp) do
        {:ok, esaml_assertion(subject: subject)} -> {:ok, map_profile(subject)}
        {:error, x} -> {:error, x}
        _ -> {:error, :invalid_assertion}
      end

    {:reply, reply, state}
  end

  @impl true
  def handle_call({:authn, relay_state}, _from, %{idp: idp, sp: sp} = state) do
    login_location = esaml_idp_metadata(idp, :login_location)
    idp_id = esaml_idp_metadata(idp, :entity_id)

    url =
      case String.contains?(to_string(idp_id), "/adfs/") do
        true ->
          sp_id = esaml_sp(sp, :entity_id)
          idp_params = %{"loginToRp" => to_string(sp_id)} |> URI.encode_query()
          to_string(login_location) <> "idpinitiatedsignon?" <> idp_params

        false ->
          idp_id
          |> :esaml_sp.generate_authn_request(sp)
          |> encode_redirect(login_location, relay_state)
      end

    {:reply, url, state}
  end

  defp map_profile(esaml_subject(name: name)) do
    name = to_string(name)
    %{user_name: name, full_name: name, email: name}
  end

  defp encode_redirect(authn_request, login_location, relay_state) do
    :esaml_binding.encode_http_redirect(login_location, authn_request, :undefined, relay_state)
  end

  defp load_config(config) do
    saml_config =
      config
      |> Keyword.drop([:sp_key, :sp_cert, :sp_trusted_fingerprints])
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
        trusted_fingerprints: trusted_fingerprints,
        org: org,
        tech: contact
      )

    idp = :esaml_util.load_metadata(saml_config[:idp_metadata_url])

    %{sp: :esaml_sp.setup(sp), idp: idp}
  end
end
