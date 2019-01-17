defmodule TdAuth.Saml do
  @moduledoc """
  Auth provider for SAML.
  """

  require Record

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

  def decode_and_validate_assertion(sp, saml_response, saml_encoding) do
    xml = :esaml_binding.decode_response(saml_encoding, saml_response)

    case :esaml_sp.validate_assertion(xml, sp) do
      {:ok, assertion} -> map_assertion_to_profile(assertion)
      {:error, x} -> {:error, x}
      _ -> {:error, :invalid_assertion}
    end
  end

  def map_assertion_to_profile(esaml_assertion(subject: subject, attributes: attributes)) do
    {:ok, map_profile(subject, attributes)}
  end

  def map_assertion_to_profile(_, _) do
    {:error, :invalid_assertion}
  end

  defp map_profile(subject, nil = _attributes) do
    map_profile(subject, Keyword.new())
  end

  defp map_profile(esaml_subject(name: subject_name), attributes) do
    map_profile(subject_name, attributes)
  end

  defp map_profile(subject_name, attributes) do
    full_name = Keyword.get(attributes, :name, subject_name)
    email = Keyword.get(attributes, :mail, subject_name)

    %{
      user_name: to_string(subject_name),
      full_name: to_string(full_name),
      email: to_string(email)
    }
  end

  def generate_metadata(sp) do
    sp
    |> :esaml_sp.generate_metadata()
    |> (fn x -> [x] end).()
    |> :xmerl.export(:xmerl_xml)
    |> List.flatten()
  end
end
