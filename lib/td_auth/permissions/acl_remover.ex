defmodule TdAuth.Permissions.AclRemover do
  @moduledoc """
  Remove stale ACL entries from deleted domains.
  """

  alias TdAuth.Permissions.AclEntries
  alias TdCache.TaxonomyCache

  require Logger

  def delete_stale_acl_entries do
    with domain_ids = [_ | _] <- TaxonomyCache.get_deleted_domain_ids() do
      {count, _entries} =
        AclEntries.delete_acl_entries(resource_type: "domain", resource_id: {:in, domain_ids})

      {structure_count, _entries} =
        AclEntries.delete_acl_entries(resource_type: "structure", resource_id: {:in, domain_ids})

      Logger.info("Deleted #{count} domain and #{structure_count} structure entries")
    end
  end
end
