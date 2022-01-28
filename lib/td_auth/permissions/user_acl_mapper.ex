defmodule TdAuth.Permissions.UserAclMapper do
  @moduledoc """
  Maps ACL Entries for UserAcl output.
  """

  alias TdAuth.Permissions.AclEntry
  alias TdCache.TaxonomyCache

  def map(%AclEntry{} = acl_entry) do
    acl_entry
    |> Map.take([:role, :group, :user_id, :resource_id])
    |> Enum.reduce(%{}, fn
      {:role, %{id: id, name: name}}, acc -> Map.put(acc, :role, %{id: id, name: name})
      {:group, %{id: id, name: name}}, acc -> Map.put(acc, :group, %{id: id, name: name})
      {:resource_id, id}, acc when not is_nil(id) -> Map.put(acc, :resource, domain(id))
      _, acc -> acc
    end)
  end

  defp domain(id) do
    name =
      case TaxonomyCache.get(id) do
        %{name: name} -> name
        _ -> nil
      end

    %{id: id, type: "domain", name: name}
  end
end
