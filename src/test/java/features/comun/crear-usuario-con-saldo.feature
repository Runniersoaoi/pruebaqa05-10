@ignore
Feature: Alta de un usuario de prueba con saldo acreditado

  Background:
    * configure headers = { 'Content-Type': 'application/json', 'x-channel': '#(channel)' }
    * def celular = generarCelular()
    * def correo = generarEmail(celular)
    * def nombre = 'Usuario ' + rol + ' QA'

  Scenario: Registrar al usuario, autenticarlo y acreditarle saldo

    Given url authUrl
    And path 'auth', 'v1', 'register'
    And request { phone: '#(celular)', fullName: '#(nombre)', email: '#(correo)', pin: '#(pinPorDefecto)' }
    When method post
    Then status 201
    And match response.user.id == '#present'
    And match response.user.status == 'ACTIVE'
    * def id = response.user.id

    Given url authUrl
    And path 'auth', 'v1', 'login'
    And request { phone: '#(celular)', pin: '#(pinPorDefecto)' }
    When method post
    Then status 200
    And match response.token == '#string'
    And match response.expiresIn == 3600
    * def token = response.token

    Given url walletUrl
    And path 'wallet', 'v1', 'deposit'
    And header Authorization = 'Bearer ' + token
    And request { amount: '#(monto)' }
    When method post
    Then status 200
    And match response.success == true
    And match response.newBalance == '#number'
    * def saldoTrasDeposito = response.newBalance
    And assert saldoTrasDeposito >= monto

    Given url walletUrl
    And path 'wallet', 'v1', 'balance'
    And header Authorization = 'Bearer ' + token
    When method get
    Then status 200
    And match response contains { balance: '#number' }
    * def saldoInicial = response.balance
    And assert saldoInicial == saldoTrasDeposito
    And assert saldoInicial >= montoTransferencia

    * print '>> Usuario', rol, '| celular:', celular, '| id:', id, '| saldo inicial:', saldoInicial
