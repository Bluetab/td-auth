defmodule TdBg.Canada.Abilities do
  @moduledoc false
  alias TdAuth.Auth.Session
  alias TdAuth.Permissions
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Permission
  alias TdAuth.Permissions.Role

  defimpl Canada.Can, for: Session do
    # administrator is superpowerful for Role and AclEntry
    def can?(%Session{is_admin: true}, _action, Role), do: true

    def can?(%Session{is_admin: true}, _action, %Role{}), do: true

    def can?(%Session{is_admin: true}, _action, AclEntry), do: true

    def can?(%Session{is_admin: true}, _action, %AclEntry{}), do: true

    def can?(
          %Session{} = session,
          :create,
          %AclEntry{principal_type: "user", resource_type: "domain", resource_id: domain_id}
        ) do
        Permissions.authorized?(session, Permission.permissions.create_acl_entry, domain_id)
    end

    def can?(%Session{} = session, :view, AclEntry) do
      Permissions.authorized?(session, Permission.permissions.view_domain, 1)
    end

    def can?(%Session{is_admin: true}, :view_acl_entries, _), do: true

    def can?(%Session{} = session, :view_acl_entries, %{resource_type: "domain", resource_id: domain_id}) do
      Permissions.authorized?(session, Permission.permissions.view_domain, domain_id)
    end

    def can?(%Session{is_admin: true}, _action, %{}), do: true

    def can?(%Session{} = _session, _action, _domain), do: false
  end
end
