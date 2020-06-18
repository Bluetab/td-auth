defmodule TdBg.Canada.Abilities do
  @moduledoc false
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Auth.Session
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Role
  alias TdCache.Permissions

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

    def can?(session, :delete, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(session, :delete_acl_entry, domain_id)
    end

    def can?(%Session{jti: jti}, :list, Group) do
      Permissions.has_any_permission_on_resource_type?(jti, [:create_acl_entry], "domain")
    end

    def can?(%Session{jti: jti}, :list, User) do
      Permissions.has_any_permission_on_resource_type?(jti, [:create_acl_entry], "domain")
    end

    def can?(%Session{jti: jti}, :list, Role) do
      Permissions.has_any_permission_on_resource_type?(jti, [:create_acl_entry], "domain")
    end

    def can?(%Session{} = _session, _action, _entity), do: false

    defp authorized?(%Session{jti: jti}, permission, domain_id) do
      Permissions.has_permission?(jti, permission, "domain", domain_id)
    end
  end
end
