defmodule TdAuth.Accounts.UserAcl do
  @moduledoc false

  alias TdAuth.Accounts
  alias TdAuth.Accounts.Group
  alias TdAuth.Accounts.User
  alias TdAuth.Permissions.AclEntry
  alias TdAuth.Permissions.Role
  alias TdAuth.Repo
  alias TdCache.TaxonomyCache

  def get_user_acls(%User{} = user) do
    user
    |> get_acl_entries
    |> do_get_user_acls
  end

  defp get_acl_entries(user) do
    gids =
      user
      |> Repo.preload(:groups)
      |> Map.get(:groups)
      |> Enum.reduce([], &[&1.id | &2])

    %{user_id: user.id, gids: gids}
    |> AclEntry.list_acl_entries_by_user_with_groups()
  end

  defp add_to_user_acl(user_acl, %{id: id, type: type}) do
    user_acl
    |> Map.put(:resource, %{id: id, type: type, name: TaxonomyCache.get_name(id)})
  end

  defp add_to_user_acl(user_acl, %Role{} = role) do
    user_acl
    |> Map.put(:role, Map.take(role, [:id, :name]))
  end

  defp add_to_user_acl(user_acl, %Group{} = group) do
    user_acl
    |> Map.put(:group, Map.take(group, [:id, :name]))
  end

  defp get_user_acl(%AclEntry{
         resource_type: resource_type,
         resource_id: resource_id,
         principal_type: "user",
         role_id: role_id
       })
       when resource_type == "domain" do
    case Role.get_role(role_id) do
      role when not is_nil(role) ->
        %{}
        |> add_to_user_acl(%{id: resource_id, type: resource_type})
        |> add_to_user_acl(role)

      _ ->
        nil
    end
  end

  defp get_user_acl(%AclEntry{
         resource_type: resource_type,
         resource_id: resource_id,
         principal_type: "group",
         principal_id: principal_id,
         role_id: role_id
       })
       when resource_type == "domain" do
    case {Role.get_role(role_id), Accounts.get_group(principal_id)} do
      {role, group} when not is_nil(role) and not is_nil(group) ->
        %{}
        |> add_to_user_acl(%{id: resource_id, type: resource_type})
        |> add_to_user_acl(role)
        |> add_to_user_acl(group)

      _ ->
        nil
    end
  end

  defp get_user_acl(_), do: nil

  defp do_get_user_acls(acl_entries) do
    acl_entries
    |> Enum.reduce([], fn acl_entry, acc ->
      case get_user_acl(acl_entry) do
        nil -> acc
        user_acl -> [user_acl | acc]
      end
    end)
  end
end
