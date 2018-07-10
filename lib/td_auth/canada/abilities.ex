defmodule TdBg.Canada.Abilities do
  @moduledoc false
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Session
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Role
  alias TdPerms.Permissions, as: PermissionCache

  defimpl Canada.Can, for: Session do
    # administrator is superpowerful
    def can?(%Session{is_admin: true}, _action, _resource), do: true

    def can?(session, :create, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(session, :create_acl_entry, domain_id)
    end

    def can?(session, :view, AclEntry) do
      authorized?(session, :view_domain, 1)
    end

    def can?(session, :view_acl_entries, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(session, :view_domain, domain_id)
    end

    def can?(session, :create_or_update, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(session, :create_acl_entry, domain_id)
    end

    def can?(session, :delete, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(session, :delete_acl_entry, domain_id)
    end

    def can?(%Session{jti: jti}, :list, Group) do
      permissions = [:create_acl_entry, :update_acl_entry]
      PermissionCache.has_any_permission?(jti, permissions, "domain")
    end

    def can?(%Session{jti: jti}, :list, User) do
      permissions = [:create_acl_entry, :update_acl_entry]
      PermissionCache.has_any_permission?(jti, permissions, "domain")
    end

    def can?(%Session{jti: jti}, :list, Role) do
      permissions = [:create_acl_entry, :update_acl_entry]
      PermissionCache.has_any_permission?(jti, permissions, "domain")
    end

    def can?(%Session{} = _session, _action, _entity), do: false

    defp authorized?(%Session{jti: jti}, permission, domain_id) do
      PermissionCache.has_permission?(jti, permission, "domain", domain_id)
    end
  end
end
