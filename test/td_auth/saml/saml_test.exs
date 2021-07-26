defmodule TdAuthWeb.AuthProvider.SamlTest do
  use ExUnit.Case

  alias TdAuth.Saml

  describe "accept_attributes/3" do
    test "filters groups by regex" do
      attributes = [
        Group: [
          'Grupo_Truedat_Acceso_Santalucia',
          'Grupo_Truedat_Acceso_Santalucia_Externo',
          'Grupo_Truedat_Acceso-guión'
        ],
        givenname: 'truedat',
        role: 'Cuenta Servicio',
        name: 'truedat'
      ]

      reject_roles = ['Externo']

      allow_groups = [
        '^Grupo_Truedat_Acceso[[:alnum:]_]*$'
      ]

      assert {true, filtered_groups} =
               Saml.accept_attributes?(attributes, reject_roles, allow_groups)

      assert Enum.member?(filtered_groups, 'Grupo_Truedat_Acceso_Santalucia')
      assert Enum.member?(filtered_groups, 'Grupo_Truedat_Acceso_Santalucia_Externo')

      refute Enum.member?(filtered_groups, 'Grupo_Truedat_Acceso-guión')
    end

    test "regex takes unicode into account" do
      attributes = [
        Group: [
          'Grupo_Truedat_Acceso_Santalucía',
          'Grupo_Truedat_Acceso_\u65e5\u672c\u8a9e'
        ],
        givenname: 'truedat',
        role: 'Cuenta Servicio',
        name: 'truedat'
      ]

      reject_roles = ['Externo']

      allow_groups = [
        '^Grupo_Truedat_Acceso[[:alnum:]_]*$'
      ]

      assert {true, filtered_groups} =
               Saml.accept_attributes?(attributes, reject_roles, allow_groups)

      assert Enum.member?(filtered_groups, 'Grupo_Truedat_Acceso_Santalucía')
      assert Enum.member?(filtered_groups, 'Grupo_Truedat_Acceso_\u65e5\u672c\u8a9e')
    end

    test "filters groups by several names in allow_groups" do
      attributes = [
        Group: [
          'Domain Users',
          'sas',
          'G_ACCESO_SLSSASP12',
          'G_Acceso_Cyberark',
          'g_cyb_truedat_show'
        ],
        givenname: 'truedat',
        role: 'Cuenta Servicio',
        name: 'truedat'
      ]

      reject_roles = ['Externo']

      allow_groups = [
        '^some_group[[:alnum:]_-]*$',
        '^G_Acceso[[:alnum:]_-]*$',
        '^g_cyb[[:alnum:]_-]*$'
      ]

      assert {true, filtered_groups} =
               Saml.accept_attributes?(attributes, reject_roles, allow_groups)

      assert Enum.member?(filtered_groups, 'G_Acceso_Cyberark')
      assert Enum.member?(filtered_groups, 'g_cyb_truedat_show')
      refute Enum.member?(filtered_groups, 'Domain Users')
      refute Enum.member?(filtered_groups, 'sas')
    end
  end

  describe "map_assertion_to_profile/4" do
    setup do
      [
        assertion:
          {:esaml_assertion, '2.0', '2021-07-09T08:17:38.128Z',
           'https://santalucia.truedat.io/callback',
           'http://fs.santalucia.es/adfs/services/trust',
           {:esaml_subject, 'truedat@santalucia.sls.inf', :undefined, :undefined, :undefined,
            :bearer, '2021-07-09T08:22:38.128Z', []},
           [
             audience: 'https://santalucia.truedat.io',
             not_on_or_after: '2021-07-09T09:17:38.112Z',
             not_before: '2021-07-09T08:17:38.112Z'
           ],
           [
             Group: [
               'Domain Users',
               'sas',
               'G_ACCESO_SLSSASP12',
               'G_Acceso_Cyberark',
               'g_cyb_truedat_show'
             ],
             givenname: 'truedat',
             role: 'Cuenta Servicio',
             name: 'truedat'
           ],
           [
             authn_context: 'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport',
             session_index: '_f60dbd1e-a872-43ab-ad1a-67851fbe6423',
             authn_instant: '2021-07-09T06:14:20.735Z'
           ]},
        reject_roles: ['Externo'],
        allow_groups: [
          '^some_group[[:alnum:]_-]*$',
          '^G_Acceso[[:alnum:]_-]*$',
          '^g_cyb[[:alnum:]_-]*$'
        ]
      ]
    end

    test "rejects login when no allow_groups are in assertion Group", %{
      assertion: assertion,
      reject_roles: reject_roles
    } do
      allow_groups_to_fail = [
        '^some_group_not_present_in_assertion[[:alnum:]_-]*$'
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
