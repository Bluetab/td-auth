Feature: User Authentication
  This feature will allow to create and identify users of the application granting them default access
  without any permission

  Scenario: logging
    When user "app-admin" tries to log into the application with password "mypass"
    Then the system returns a result with code "Created"

  Scenario: logging error
    When user "app-admin" tries to log into the application with password "inventedpass"
    Then the system returns a result with code "Forbidden"

  Scenario: logging error for non existing user
    When user "nobody" tries to log into the application with password "inventedpass"
    Then the system returns a result with code "Forbidden"

  Scenario: Creating a New user in the application
    Given user "app-admin" is logged in the application with password "mypass"
    When "app-admin" tries to create a user "newuser" with password "new-password"
    Then the system returns a result with code "Created"
    And user "newuser" can be authenticated with password "new-password"

   Scenario: Check whether user is superadmin when creating new user
     Given an existing user "johndoe" with password "secret" without "super-admin" permission
     And user "johndoe" is logged in the application with password "secret"
     When "johndoe" tries to create a user "newuser" with password "new-password"
     Then the system returns a result with code "Forbidden"
     And user "newuser" can not be authenticated with password "new-password"

  Scenario: Error when creating a new user in the application by a non admin user
    Given an existing user "nobody" with password "inventedpass" without "super-admin" permission
    And user "nobody" is logged in the application with password "inventedpass"
    When "nobody" tries to create a user "newuser" with password "newpass"
    Then the system returns a result with code "Forbidden"
    And user "newuser" can not be authenticated with password "newpass"

  # Scenario: Assigning super-admin permission to an existing user
  #   Given an existing user "nobody" with password "mypass" without "super-admin" permission
  #   And user "app-admin" is logged in the application with password "mypass"
  #   When "app-admin" tries to assign "super-admin" permission to "nobody"
  #   Then the system returns a result with code "Ok"
  #   And user "nobody" can be authenticated with password "mypass" with "super-admin" permission
  #
  # Scenario: Error when assigning super-admin permission to an existing user
  #   Given an existing user "nobody" with password "mypass" with "super-admin" permission
  #   And an existing user "John Doe" with password "mypass" without "super-admin" permission
  #   And user "nobody" is logged in the application with password "mypass"
  #   When "nobody" tries to assign "super-admin" permission to "John Doe"
  #   Then the system returns a result with code "Forbidden"
  #   And user "John Doe" can be authenticated with password "mypass" without "super-admin" permission

  Scenario: Error when creating a duplicated user
    Given an existing user "uniqueuser" with password "mypass" with "super-admin" permission
    And user "app-admin" is logged in the application with password "mypass"
    When "app-admin" tries to create a user "uniqueuser" with password "new-password"
    Then the system returns a result with code "Unprocessable Entity"
    And user "uniqueuser" can not be authenticated with password "new-password"
    And user "uniqueuser" can be authenticated with password "mypass"

  Scenario: Password modification
    Given an existing user "johndoe" with password "secret" without "super-admin" permission
    And user "johndoe" is logged in the application with password "secret"
    When "johndoe" tries to modify his password with following data:
      | old_password | new_password |
      | secret       | newsecret    |
    Then the system returns a result with code "Ok"
    And user "johndoe" can not be authenticated with password "secret"
    And user "johndoe" can be authenticated with password "newsecret"

   Scenario Outline: Check whether user is superadmin when modifying another user
     Given an existing user "<user>" with password "secret" with super-admin property <isadmin>
     And an existing user "user" with password "userpass" without "super-admin" permission
     And user "<user>" is logged in the application with password "secret"
     When user "<user>" tries to modify user "user" with following data:
       | is_admin |
       | false    |
     Then the system returns a result with code "<result>"

     Examples:
       | user      | isadmin   | result    |
       | superad   | yes       | Ok        |
       | johndoe   | no        | Forbidden |



  Scenario: Password modification error
    Given an existing user "johndoe" with password "secret" without "super-admin" permission
    And user "johndoe" is logged in the application with password "secret"
    When "johndoe" tries to modify his password with following data:
      | old_password | new_password |
      | dontknow     | newsecret    |
    Then the system returns a result with code "Unprocessable Entity"
    And user "johndoe" can not be authenticated with password "newsecret"
    And user "johndoe" can be authenticated with password "secret"

  # Scenario Outline: Delete user only when user is superadmin
  #   Given an existing user <user> with password "secret" with super-admin property <isadmin>
  #   And an existing user "user" with password "userpass" without "super-admin" permission
  #   And user <user> is logged in the application with password "secret"
  #   When user <user> tries to delete user "user"
  #   Then the system returns a result with code <result>
  #   And if result <result> is "Ok" user "user" can not be authenticated with password "secret"
  #   And if result <result> is not "Ok" user "user" can be authenticated with password "secret"
  #
  #   Examples:
  #     | user      | isadmin   | result    |
  #     | superad   | yes       | Ok        |
  #     | johndoe   | no        | Forbidden |
