defmodule TdBg.Canada.Abilities do
  @moduledoc false
  alias TdAuth.Auth.Claims
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Role
  alias TdCache.Permissions

  defimpl Canada.Can, for: Claims do
    # administrator is superpowerful
    def can?(%Claims{role: "admin"}, _action, _resource), do: true

    # Metrics connector can view all resources
    def can?(%Claims{role: "service"}, :view, _resource), do: true

    def can?(claims, :create, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(claims, :create_acl_entry, domain_id)
    end

    def can?(claims, :update, %{resource_type: "domain", resource_id: domain_id}) do
      authorized?(claims, :update_acl_entry, domain_id)
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

    # All logged in users can list roles
    def can?(%Claims{}, :view, Role), do: true

    def can?(%Claims{}, _action, _entity), do: false

    defp authorized?(%Claims{jti: jti}, permission, domain_id) do
      Permissions.has_permission?(jti, permission, "domain", domain_id)
    end
  end
end
