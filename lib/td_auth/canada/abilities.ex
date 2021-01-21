defmodule TdBg.Canada.Abilities do
  @moduledoc false
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Claims
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Role
  alias TdCache.Permissions

  defimpl Canada.Can, for: Claims do
    @notification_groups ["business_glossary_view", "business_glossary_management"]

    # administrator is superpowerful
    def can?(%Claims{is_admin: true}, _action, _resource), do: true

    def can?(claims, :create, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(claims, :create_acl_entry, domain_id)
    end

    def can?(claims, :view, AclEntry) do
      authorized?(claims, :view_domain, 1)
    end

    def can?(claims, :view_acl_entries, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(claims, :view_domain, domain_id)
    end

    def can?(claims, :delete, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(claims, :delete_acl_entry, domain_id)
    end

    def can?(%Claims{jti: jti, groups: groups}, :list, Group) do
      Permissions.has_any_permission_on_resource_type?(jti, [:create_acl_entry], "domain") or
        Enum.any?(@notification_groups, &(&1 in groups))
    end

    def can?(%Claims{jti: jti, groups: groups}, :list, User) do
      Permissions.has_any_permission_on_resource_type?(jti, [:create_acl_entry], "domain") or
        Enum.any?(@notification_groups, &(&1 in groups))
    end

    def can?(%Claims{jti: jti}, :list, Role) do
      Permissions.has_any_permission_on_resource_type?(jti, [:create_acl_entry], "domain")
    end

    def can?(%Claims{}, _action, _entity), do: false

    defp authorized?(%Claims{jti: jti}, permission, domain_id) do
      Permissions.has_permission?(jti, permission, "domain", domain_id)
    end
  end
end
