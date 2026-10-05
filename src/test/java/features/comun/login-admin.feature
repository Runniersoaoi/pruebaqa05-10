@ignore
Feature: Autenticacion en el backoffice administrativo

  Scenario: Obtener el token de administrador

    Given url adminUrl
    And path 'admin', 'v1', 'login'
    And header Content-Type = 'application/json'
    And header x-channel = adminChannel
    And request { username: '#(adminUser.username)', password: '#(adminUser.password)' }
    When method post
    Then status 200
    And match response.token == '#string'
    And match response.expiresIn == 14400
    * def tokenAdmin = response.token
