defmodule TdAuth.Saml do
  @moduledoc """
  Auth provider for SAML.
  """

  require Logger
  require Record

  alias TdAuth.Accounts

  @esaml_lib "esaml/include/esaml.hrl"

  Record.defrecord(:esaml_assertion, Record.extract(:esaml_assertion, from_lib: @esaml_lib))
  Record.defrecord(:esaml_subject, Record.extract(:esaml_subject, from_lib: @esaml_lib))
  Record.defrecord(:esaml_idp_metadata, Record.extract(:esaml_idp_metadata, from_lib: @esaml_lib))
  Record.defrecord(:esaml_sp, Record.extract(:esaml_sp, from_lib: @esaml_lib))

  def generate_authn_redirect_url(idp, sp, relay_state) do
    login_location = esaml_idp_metadata(idp, :login_location)
    idp_id = esaml_idp_metadata(idp, :entity_id)

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
  end

  defp encode_redirect(authn_request, login_location, relay_state) do
    :esaml_binding.encode_http_redirect(login_location, authn_request, :undefined, relay_state)
  end

  def decode_and_validate_assertion(
        sp,
        saml_response,
        saml_encoding,
        reject_roles,
        allow_groups,
        create_group
      ) do
    xml = :esaml_binding.decode_response(saml_encoding, saml_response)

    case :esaml_sp.validate_assertion(xml, sp) do
      {:ok, assertion} ->
        map_assertion_to_profile(assertion, reject_roles, allow_groups, create_group)

      {:error, x} ->
        {:error, x}

      _ ->
        {:error, :invalid_assertion}
    end
  end

  def map_assertion_to_profile(
        esaml_assertion(subject: subject, attributes: attributes) = assertion,
        reject_roles,
        allow_groups,
        create_group
      ) do
    case accept_attributes?(attributes, reject_roles, allow_groups) do
      {true, filtered_groups} ->
        {:ok, map_profile(subject, attributes, filtered_groups, create_group)}

      {_, _} ->
        {:error, :rejected}
    end
  end

  def map_assertion_to_profile(_, _, _, _) do
    {:error, :invalid_assertion}
  end

  def accept_attributes?(attributes, reject_roles, allow_groups) do
    role = Keyword.get(attributes, :role)
    groups = Keyword.get(attributes, :Group)
    role_rejected = Enum.member?(reject_roles, role)

    allowed_groups =
      Enum.filter(
        groups,
        fn group ->
          Enum.any?(
            allow_groups,
            fn group_allowed ->
              String.match?(to_string(group), ~r/#{group_allowed}/u)
            end
          )
        end
      )

    if role_rejected, do: Logger.info("Rejected assertion for #{inspect(attributes)}")
    {not role_rejected and not Enum.empty?(allowed_groups), allowed_groups}
  end

  defp map_profile(subject, nil = _attributes, filtered_groups, create_group) do
    map_profile(subject, Keyword.new(), filtered_groups, create_group)
  end

  defp map_profile(esaml_subject(name: subject_name), attributes, filtered_groups, create_group) do
    map_profile(subject_name, attributes, filtered_groups, create_group)
  end

  defp map_profile(subject_name, attributes, filtered_groups, create_group) do
    full_name = Keyword.get(attributes, :name, subject_name)
    email = Keyword.get(attributes, :mail, subject_name)

    %{
      user_name: to_string(subject_name),
      full_name: to_string(full_name),
      email: to_string(email)
    }
    |> maybe_put_groups(filtered_groups, create_group)
  end

  defp maybe_put_groups(profile, filtered_groups, true) do
    Map.put(profile, :groups, Enum.map(filtered_groups, fn group -> to_string(group) end))
  end

  defp maybe_put_groups(profile, _filtered_groups, _), do: profile

  def generate_metadata(sp) do
    sp
    |> :esaml_sp.generate_metadata()
    |> (fn x -> [x] end).()
    |> :xmerl.export(:xmerl_xml)
    |> List.flatten()
  end
end
