Feature: User Authentication
  This feature will allow to create and identify users of the application granting them default access
  without any permission

  Background:
    Given an initial admin user "app-admin" is created with password "mypass"

  Scenario: logging
    When user "app-admin" tries to log into the application with password "mypass"
    Then the system returns a result with code "Created"

  Scenario: logging error
    When user "app-admin" tries to log into the application with password "inventedpass"
    Then the system returns a result with code "Unauthorized"

  Scenario: logging error for non existing user
    When user "nobody" tries to log into the application with password "inventedpass"
    Then the system returns a result with code "Unauthorized"

  Scenario: Creating a New user in the application
    And user "app-admin" is logged in the application with password "mypass"
    When "app-admin" tries to create a user "newuser" with password "new-password"
    Then the system returns a result with code "Created"
    And user "newuser" can be authenticated with password "new-password"

  Scenario: Check whether user is superadmin when creating new user
    Given an existing user "johndoe" with password "secret"
    And user "johndoe" is logged in the application with password "secret"
    When "johndoe" tries to create a user "newuser" with password "new-password"
    Then the system returns a result with code "Forbidden"
    And user "newuser" can not be authenticated with password "new-password"

  Scenario: Error when creating a new user in the application by a non admin user
    Given an existing user "nobody" with password "inventedpass"
    And user "nobody" is logged in the application with password "inventedpass"
    When "nobody" tries to create a user "newuser" with password "newpass"
    Then the system returns a result with code "Forbidden"
    And user "newuser" can not be authenticated with password "newpass"

  # Scenario: Assigning super-admin permission to an existing user
  #   Given an existing user "nobody" with password "mypass"
  #   And user "app-admin" is logged in the application with password "mypass"
  #   When "app-admin" tries to assign "super-admin" permission to "nobody"
  #   Then the system returns a result with code "Ok"
  #   And user "nobody" can be authenticated with password "mypass" with "super-admin" permission
  #
  # Scenario: Error when assigning super-admin permission to an existing user
  #   Given an existing user "nobody" with password "mypass" with "super-admin" permission
  #   And an existing user "John Doe" with password "mypass"
  #   And user "nobody" is logged in the application with password "mypass"
  #   When "nobody" tries to assign "super-admin" permission to "John Doe"
  #   Then the system returns a result with code "Forbidden"
  #   And user "John Doe" can be authenticated with password "mypass"

  Scenario: Error when creating a duplicated user
    Given an existing user "uniqueuser" with password "mypass" with "super-admin" permission
    And user "app-admin" is logged in the application with password "mypass"
    When "app-admin" tries to create a user "uniqueuser" with password "new-password"
    Then the system returns a result with code "Unprocessable Entity"
    And user "uniqueuser" can not be authenticated with password "new-password"
    And user "uniqueuser" can be authenticated with password "mypass"

  Scenario: Password modification
    Given an existing user "johndoe" with password "secret"
    And user "johndoe" is logged in the application with password "secret"
    When "johndoe" tries to modify his password with following data:
      | old_password | new_password |
      | secret       | newsecret    |
    Then the system returns a result with code "Ok"
    And user "johndoe" can not be authenticated with password "secret"
    And user "johndoe" can be authenticated with password "newsecret"

  Scenario Outline: Check whether user is superadmin when modifying another user
    Given an existing user "<user>" with password "secret" with role "<role>"
    And an existing user "user" with password "userpass"
    And user "<user>" is logged in the application with password "secret"
    When user "<user>" tries to modify user "user" with following data:
      | is_admin |
      | false    |
    Then the system returns a result with code "<result>"

    Examples:
      | user    | role  | result    |
      | superad | admin | Ok        |
      | johndoe | user  | Forbidden |

  Scenario: Password modification error
    Given an existing user "johndoe" with password "secret"
    And user "johndoe" is logged in the application with password "secret"
    When "johndoe" tries to modify his password with following data:
      | old_password | new_password |
      | dontknow     | newsecret    |
    Then the system returns a result with code "Unauthorized"
    And user "johndoe" can not be authenticated with password "newsecret"
    And user "johndoe" can be authenticated with password "secret"

  Scenario: Password modification error 2
    Given an existing user "johndoe" with password "secret"
    Given an existing user "dashelle" with password "secret"
    And user "johndoe" is logged in the application with password "secret"
    When "johndoe" tries to modify "dashelle" password with following data:
      | old_password | new_password |
      | secret       | newsecret    |
    Then the system returns a result with code "Forbidden"
    And user "dashelle" can not be authenticated with password "newsecret"
    And user "dashelle" can be authenticated with password "secret"

  Scenario Outline: Delete user only when user is superadmin
    Given an existing user "<user>" with password "secret" with role "<role>"
    And an existing user "user" with password "userpass"
    And user "<user>" is logged in the application with password "secret"
    When user "<user>" tries to delete user "user"
    Then the system returns a result with code "<result>"
    And if result "<result>" is "No Content" user "user" does not exist
    And if result "<result>" is not "No Content" user "user" can be authenticated with password "userpass"

    Examples:
      | user    | role  | result     |
      | superad | admin | No Content |
      | johndoe | user  | Forbidden  |

  Scenario Outline: Reset password when user is superadmin
    Given an existing user "johndoe" with password "secret"
    And an existing user "<user>" with password "secret" with role "<role>"
    And user "<user>" is logged in the application with password "secret"
    When "<user>" tries to reset "johndoe" password with new_password "newsecret"
    Then the system returns a result with code "<result>"
    And if result "<result>" is not "Forbidden" user "johndoe" can be authenticated with password "newsecret"
    ##  It is no longer to change the password with /api/users now  it is necessary
    ## to do it by /api/password
    Examples:
      | user     | role  | result    |
      | superad  | admin | Forbidden |
      | dashelle | user  | Forbidden |

  Scenario Outline: User updates own properties
    Given an existing user "<user>" with password "secret" with role "<role>"
    And user "<user>" is logged in the application with password "secret"
    When "<user>" tries to reset his "<property>" with new property value "<new_value"
    Then the system returns a result with code "<result>"

    Examples:
      | user     | role  | property  | new_value      | result    |
      | superad  | admin | full_name | New Super Ad   | Ok        |
      | superad  | admin | password  | newsecret      | Forbidden |
      | dashelle | user  | full_name | New John Doe   | Ok        |
      | dashelle | user  | email     | john@email.com | Ok        |
      | dashelle | user  | password  | newsecret      | Forbidden |
