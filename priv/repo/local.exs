# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TdAuth.Repo.insert!(%TdAuth.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Ecto.Changeset
alias TdAuth.Accounts.Group
alias TdAuth.Accounts.User
alias TdAuth.Permissions.AclEntry
alias TdAuth.Permissions.Role
alias TdAuth.Repo

user1 = Repo.insert!(%User{
  user_name: "user1",
  password_hash: "$2b$12$EtLeBV/oVeaL74bgotO1SuRfMDtaT6MOzBNFk7gU29tsEPupyUFJm",
  email: "user1@bluetab.net",
  full_name: "User 1",
  is_admin: false,
  is_protected: false
}) # id 3

user2 = Repo.insert!(%User{
  user_name: "user2",
  password_hash: "$2b$12$EtLeBV/oVeaL74bgotO1SuRfMDtaT6MOzBNFk7gU29tsEPupyUFJm",
  email: "user2@bluetab.net",
  full_name: "User 2",
  is_admin: false,
  is_protected: false
}) # id 4

user3 = Repo.insert!(%User{
  user_name: "user3",
  password_hash: "$2b$12$EtLeBV/oVeaL74bgotO1SuRfMDtaT6MOzBNFk7gU29tsEPupyUFJm",
  email: "user3@bluetab.net",
  full_name: "User 3",
  is_admin: false,
  is_protected: false
}) # id 5

group1 = Repo.insert!(%Group{
  name: "group1",
  description: "group 1"
})

group2 = Repo.insert!(%Group{
  name: "group2",
  description: "group 2"
})

group3 = Repo.insert!(%Group{
  name: "group3",
  description: "group 3"
})

role1 = Repo.insert!(%Role{
  name: "role1"
})

role2 = Repo.insert!(%Role{
  name: "role2"
})

role3 = Repo.insert!(%Role{
  name: "role3"
})

user1
|> Repo.preload(:groups)
|> Changeset.change
|> Changeset.put_assoc(:groups, [group1])
|> Repo.update!


user2
|> Repo.preload(:groups)
|> Changeset.change
|> Changeset.put_assoc(:groups, [group1, group2])
|> Repo.update!

user3
|> Repo.preload(:groups)
|> Changeset.change
|> Changeset.put_assoc(:groups, [group1, group2, group3])
|> Repo.update!

Repo.insert(%AclEntry{
  principal_id: user3.id,
  principal_type: "user",
  resource_id: 1,
  resource_type: "domain",
  role_id: role1.id
})

Repo.insert(%AclEntry{
  principal_id: user3.id,
  principal_type: "user",
  resource_id: 2,
  resource_type: "domain",
  role_id: role2.id
})

Repo.insert(%AclEntry{
  principal_id: user3.id,
  principal_type: "user",
  resource_id: 3,
  resource_type: "domain",
  role_id: role3.id
})

Repo.insert(%AclEntry{
  principal_id: group1.id,
  principal_type: "group",
  resource_id: 1,
  resource_type: "domain",
  role_id: role1.id
})

Repo.insert(%AclEntry{
  principal_id: group2.id,
  principal_type: "group",
  resource_id: 2,
  resource_type: "domain",
  role_id: role2.id
})

Repo.insert(%AclEntry{
  principal_id: group3.id,
  principal_type: "group",
  resource_id: 3,
  resource_type: "domain",
  role_id: role3.id
})
