@regresion
Feature: Regresion de la Billetera Digital Enterprise

  Background:
    # El header x-channel es obligatorio en toda peticion de la API:
    # si falta, la respuesta es 400 con el codigo GEN_001.
    * configure headers = { 'Content-Type': 'application/json', 'x-channel': '#(channel)' }


  @escenario1
  Scenario: Escenario 1 - Registro de los usuarios Emisor y Receptor con saldo asignado

    * def emisor = call read('classpath:features/comun/crear-usuario-con-saldo.feature') { rol: 'Emisor', monto: '#(montoDeposito)' }
    * def receptor = call read('classpath:features/comun/crear-usuario-con-saldo.feature') { rol: 'Receptor', monto: '#(montoDeposito)' }

    And assert emisor.id != receptor.id
    And assert emisor.celular != receptor.celular

    * eval store.set('emisor.id', emisor.id)
    * eval store.set('emisor.celular', emisor.celular)
    * eval store.set('emisor.saldoInicial', emisor.saldoInicial)

    * eval store.set('receptor.id', receptor.id)
    * eval store.set('receptor.celular', receptor.celular)
    * eval store.set('receptor.saldoInicial', receptor.saldoInicial)

    * print '>> Estado global tras el Escenario 1:', store.snapshot()

    Given url authUrl
    And path 'auth', 'v1', 'register'
    And request { phone: '#(emisor.celular)', fullName: 'Usuario Emisor Duplicado', email: '#(emisor.correo)', pin: '#(pinPorDefecto)' }
    When method post
    Then status 409
    And match response.code == 'AUTH_006'
    And match response.message == '#string'


  @escenario2
  Scenario: Escenario 2 - Transferencia de saldo del Emisor al Receptor

    * def celularEmisor = store.getString('emisor.celular')
    * def idReceptor = store.getString('receptor.id')
    * def saldoInicialEmisor = store.getDouble('emisor.saldoInicial')
    And assert celularEmisor != null

    Given url authUrl
    And path 'auth', 'v1', 'login'
    And request { phone: '#(celularEmisor)', pin: '#(pinPorDefecto)' }
    When method post
    Then status 200
    And match response.token == '#string'
    * def tokenEmisor = response.token

    Given url transactionUrl
    And path 'transaction', 'v1', 'transfer'
    And header Authorization = 'Bearer ' + tokenEmisor
    And request { recipientId: '#(idReceptor)', amount: '#(montoTransferencia)', description: '#(notaTransferencia)' }
    When method post
    Then status 200
    And match response contains { status: 'COMPLETED' }
    And match response.transactionId == '#string'
    And match response.referenceCode == '#string'

    * def codigoTransaccion = response.transactionId
    * def codigoReferencia = response.referenceCode
    * eval store.set('transaccion.id', codigoTransaccion)
    * eval store.set('transaccion.referencia', codigoReferencia)

    Given url walletUrl
    And path 'wallet', 'v1', 'balance'
    And header Authorization = 'Bearer ' + tokenEmisor
    When method get
    Then status 200
    * def saldoFinalEmisor = response.balance

    * def saldoEsperado = saldoInicialEmisor - montoTransferencia
    And assert saldoFinalEmisor == saldoEsperado

    * eval store.set('emisor.saldoFinal', saldoFinalEmisor)
    * print '>> Emisor | saldo inicial:', saldoInicialEmisor, '| transferido:', montoTransferencia, '| saldo final:', saldoFinalEmisor, '| transaccion:', codigoTransaccion


  @escenario3
  Scenario: Escenario 3 - Validacion de la transferencia en el usuario Receptor

    * def celularReceptor = store.getString('receptor.celular')
    * def celularEmisor = store.getString('emisor.celular')
    * def idReceptor = store.getString('receptor.id')
    * def idEmisor = store.getString('emisor.id')
    * def saldoInicialReceptor = store.getDouble('receptor.saldoInicial')
    * def codigoReferencia = store.getString('transaccion.referencia')
    And assert codigoReferencia != null

    Given url authUrl
    And path 'auth', 'v1', 'login'
    And request { phone: '#(celularReceptor)', pin: '#(pinPorDefecto)' }
    When method post
    Then status 200
    And match response.token == '#string'
    * def tokenReceptor = response.token

    Given url walletUrl
    And path 'wallet', 'v1', 'balance'
    And header Authorization = 'Bearer ' + tokenReceptor
    When method get
    Then status 200
    * def saldoFinalReceptor = response.balance

    * def saldoEsperado = saldoInicialReceptor + montoTransferencia
    And assert saldoFinalReceptor == saldoEsperado
    * eval store.set('receptor.saldoFinal', saldoFinalReceptor)

    * def admin = call read('classpath:features/comun/login-admin.feature')

    Given url adminUrl
    And path 'admin', 'v1', 'transactions'
    And header Authorization = 'Bearer ' + admin.tokenAdmin
    And header x-channel = adminChannel
    When method get
    Then status 200
    And match response == '#[_ > 0]'

    * def transaccionesReceptor = karate.filter(response, function(t){ return t.userId == idReceptor })
    And match transaccionesReceptor == '#[2]'

    * def transferenciaRecibida = karate.filter(transaccionesReceptor, function(t){ return t.referenceCode == codigoReferencia })
    And match transferenciaRecibida == '#[1]'
    And match transferenciaRecibida[0].type == 'INCOME'
    And match transferenciaRecibida[0].amount == montoTransferencia
    And match transferenciaRecibida[0].counterpartyPhone == celularEmisor
    And assert transferenciaRecibida[0].description.indexOf(notaTransferencia) != -1

    * print '>> Receptor | saldo inicial:', saldoInicialReceptor, '| recibido:', montoTransferencia, '| saldo final:', saldoFinalReceptor
