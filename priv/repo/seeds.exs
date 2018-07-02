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
alias TdAuth.Accounts.User
alias TdAuth.Permissions.Permission
alias TdAuth.Repo

users = [
  %User{user_name: "lwillimont2", password: "password", email: "lsargood2@marriott.com", full_name: "Latrena", is_admin: false, is_protected: false},
  %User{user_name: "aallbones5", password: "password", email: "aonion5@ca.gov", full_name: "Arleyne", is_admin: true, is_protected: false},
  %User{user_name: "tfordham6", password: "password", email: "tfigg6@bloglovin.com", full_name: "Theresa", is_admin: false, is_protected: false},
  %User{user_name: "bmogg7", password: "password", email: "bhollyer7@apache.org", full_name: "Berna", is_admin: false, is_protected: false},
  %User{user_name: "tbaudi8", password: "password", email: "tsalling8@army.mil", full_name: "Trumann", is_admin: true, is_protected: false},
  %User{user_name: "cnajera9", password: "password", email: "cstoile9@google.co.jp", full_name: "Cristine", is_admin: false, is_protected: false},
  %User{user_name: "ejimmisona", password: "password", email: "emacgauhya@discovery.com", full_name: "Esmaria", is_admin: false, is_protected: false},
  %User{user_name: "jmessrutherb", password: "password", email: "jaskinb@nsw.gov.au", full_name: "Jacki", is_admin: true, is_protected: false},
  %User{user_name: "tbuckettc", password: "password", email: "tbrewinc@ifeng.com", full_name: "Tomas", is_admin: true, is_protected: false},
  %User{user_name: "fspridgend", password: "password", email: "fgravestond@sina.com.cn", full_name: "Francklin", is_admin: true, is_protected: false},
  %User{user_name: "smadeleye", password: "password", email: "ssheridane@fema.gov", full_name: "Shanan", is_admin: true, is_protected: false},
  %User{user_name: "hcrippellg", password: "password", email: "hmaudsleyg@utexas.edu", full_name: "Harmonie", is_admin: true, is_protected: false},
  %User{user_name: "aheamush", password: "password", email: "amacadamh@house.gov", full_name: "Ambrosio", is_admin: false, is_protected: false},
  %User{user_name: "glubertii", password: "password", email: "gfeei@wix.com", full_name: "Griffie", is_admin: false, is_protected: false},
  %User{user_name: "pscardifield0", password: "password", email: "pdubique0@amazon.co.uk", full_name: "Pippo Modified", is_admin: false, is_protected: false},
  %User{user_name: "kjoanic1", password: "password", email: "ksirett1@livejournal.com", full_name: "Kerasd", is_admin: true, is_protected: false},
  %User{user_name: "juan", password: "password", email: "juan.alvarez@bluetab.net", full_name: "Juan Álvarez", is_admin: true, is_protected: false},
  %User{user_name: "fagutter3", password: "password", email: "fhearnden3@yellowbook.com", full_name: "Filberto", is_admin: false, is_protected: false}
]

for user <- users do
  user |> Repo.insert!
end

get_permission = fn(name) ->
case Repo.get_by(Permission, name: name) do
  nil -> Repo.insert!(%Permission{name: name})
  permission -> permission
end
end

Permission.permissions.create_acl_entry |> get_permission.()
Permission.permissions.update_acl_entry |> get_permission.()
Permission.permissions.delete_acl_entry |> get_permission.()

Permission.permissions.create_domain |> get_permission.()
Permission.permissions.update_domain |> get_permission.()
Permission.permissions.delete_domain |> get_permission.()
Permission.permissions.view_domain |> get_permission.()

Permission.permissions.create_business_concept |> get_permission.()
Permission.permissions.delete_business_concept |> get_permission.()
Permission.permissions.deprecate_business_concept |> get_permission.()
Permission.permissions.manage_business_concept_alias |> get_permission.()
Permission.permissions.publish_business_concept |> get_permission.()
Permission.permissions.reject_business_concept |> get_permission.()
Permission.permissions.send_business_concept_for_approval |> get_permission.()
Permission.permissions.update_business_concept |> get_permission.()
Permission.permissions.view_approval_pending_business_concepts |> get_permission.()
Permission.permissions.view_deprecated_business_concepts |> get_permission.()
Permission.permissions.view_draft_business_concepts |> get_permission.()
Permission.permissions.view_published_business_concepts |> get_permission.()
Permission.permissions.view_rejected_business_concepts |> get_permission.()
Permission.permissions.view_versioned_business_concepts |> get_permission.()
