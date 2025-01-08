defmodule TdAuthWeb.AuthProvider.SamlTest do
  use ExUnit.Case

  alias TdAuth.Saml

  describe "accept_attributes/3" do
    test "filters groups by regex" do
      attributes = [
        Group: [
          ~c"Grupo_Truedat_Acceso_Santalucia",
          ~c"Grupo_Truedat_Acceso_Santalucia_Externo",
          ~c"Grupo_Truedat_Acceso-guión"
        ],
        givenname: ~c"truedat",
        role: ~c"Cuenta Servicio",
        name: ~c"truedat"
      ]

      reject_roles = [~c"Externo"]

      allow_groups = [
        ~c"^Grupo_Truedat_Acceso[[:alnum:]_]*$"
      ]

      assert {true, filtered_groups} =
               Saml.accept_attributes?(attributes, reject_roles, allow_groups)

      assert Enum.member?(filtered_groups, ~c"Grupo_Truedat_Acceso_Santalucia")
      assert Enum.member?(filtered_groups, ~c"Grupo_Truedat_Acceso_Santalucia_Externo")

      refute Enum.member?(filtered_groups, ~c"Grupo_Truedat_Acceso-guión")
    end

    test "regex takes unicode into account" do
      attributes = [
        Group: [
          ~c"Grupo_Truedat_Acceso_Santalucía",
          ~c"Grupo_Truedat_Acceso_\u65e5\u672c\u8a9e"
        ],
        givenname: ~c"truedat",
        role: ~c"Cuenta Servicio",
        name: ~c"truedat"
      ]

      reject_roles = [~c"Externo"]

      allow_groups = [
        ~c"^Grupo_Truedat_Acceso[[:alnum:]_]*$"
      ]

      assert {true, filtered_groups} =
               Saml.accept_attributes?(attributes, reject_roles, allow_groups)

      assert Enum.member?(filtered_groups, ~c"Grupo_Truedat_Acceso_Santalucía")
      assert Enum.member?(filtered_groups, ~c"Grupo_Truedat_Acceso_\u65e5\u672c\u8a9e")
    end

    test "filters groups by several names in allow_groups" do
      attributes = [
        Group: [
          ~c"Domain Users",
          ~c"sas",
          ~c"G_ACCESO_SLSSASP12",
          ~c"G_Acceso_Cyberark",
          ~c"g_cyb_truedat_show"
        ],
        givenname: ~c"truedat",
        role: ~c"Cuenta Servicio",
        name: ~c"truedat"
      ]

      reject_roles = [~c"Externo"]

      allow_groups = [
        ~c"^some_group[[:alnum:]_-]*$",
        ~c"^G_Acceso[[:alnum:]_-]*$",
        ~c"^g_cyb[[:alnum:]_-]*$"
      ]

      assert {true, filtered_groups} =
               Saml.accept_attributes?(attributes, reject_roles, allow_groups)

      assert Enum.member?(filtered_groups, ~c"G_Acceso_Cyberark")
      assert Enum.member?(filtered_groups, ~c"g_cyb_truedat_show")
      refute Enum.member?(filtered_groups, ~c"Domain Users")
      refute Enum.member?(filtered_groups, ~c"sas")
    end
  end

  describe "map_assertion_to_profile/4" do
    setup do
      [
        assertion:
          {:esaml_assertion, ~c"2.0", ~c"2021-07-09T08:17:38.128Z",
           ~c"https://santalucia.truedat.io/callback",
           ~c"http://fs.santalucia.es/adfs/services/trust",
           {:esaml_subject, ~c"truedat@santalucia.sls.inf", :undefined, :undefined, :undefined,
            :bearer, ~c"2021-07-09T08:22:38.128Z", []},
           [
             audience: ~c"https://santalucia.truedat.io",
             not_on_or_after: ~c"2021-07-09T09:17:38.112Z",
             not_before: ~c"2021-07-09T08:17:38.112Z"
           ],
           [
             Group: [
               ~c"Domain Users",
               ~c"sas",
               ~c"G_ACCESO_SLSSASP12",
               ~c"G_Acceso_Cyberark",
               ~c"g_cyb_truedat_show"
             ],
             givenname: ~c"truedat",
             role: ~c"Cuenta Servicio",
             name: ~c"truedat"
           ],
           [
             authn_context: ~c"urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport",
             session_index: ~c"_f60dbd1e-a872-43ab-ad1a-67851fbe6423",
             authn_instant: ~c"2021-07-09T06:14:20.735Z"
           ]},
        reject_roles: [~c"Externo"],
        allow_groups: [
          ~c"^some_group[[:alnum:]_-]*$",
          ~c"^G_Acceso[[:alnum:]_-]*$",
          ~c"^g_cyb[[:alnum:]_-]*$"
        ]
      ]
    end

    test "rejects login when no allow_groups are in assertion Group", %{
      assertion: assertion,
      reject_roles: reject_roles
    } do
      allow_groups_to_fail = [
        ~c"^some_group_not_present_in_assertion[[:alnum:]_-]*$"
      ]

      assert {:error, :rejected} =
               Saml.map_assertion_to_profile(assertion, reject_roles, allow_groups_to_fail, true)

      assert {:error, :rejected} =
               Saml.map_assertion_to_profile(assertion, reject_roles, allow_groups_to_fail, false)
    end

    test "accepts login; adds new groups to profile when create_groups is true", %{
      assertion: assertion,
      reject_roles: reject_roles,
      allow_groups: allow_groups
    } do
      assert {:ok, profile} =
               Saml.map_assertion_to_profile(assertion, reject_roles, allow_groups, true)

      assert Map.has_key?(profile, :groups)
      assert profile.groups == ["G_Acceso_Cyberark", "g_cyb_truedat_show"]
    end

    test "accepts login; no groups are added to profile when create_groups is false", %{
      assertion: assertion,
      reject_roles: reject_roles,
      allow_groups: allow_groups
    } do
      assert {:ok, profile} =
               Saml.map_assertion_to_profile(assertion, reject_roles, allow_groups, false)

      refute Map.has_key?(profile, :groups)
    end
  end
end
