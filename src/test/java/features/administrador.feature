@administrador
Feature: Flujo Administrador - Validacion de la transaccion desde el backoffice

  Background:
    * configure headers = { 'Content-Type': 'application/json', 'x-channel': '#(adminChannel)' }
    * def admin = call read('classpath:features/comun/login-admin.feature')
    * def tokenAdmin = admin.tokenAdmin


  @admin-transaccion
  Scenario: Validar la transaccion de la operacion en la auditoria global

    * def codigoReferencia = store.getString('transaccion.referencia')
    * def idEmisor = store.getString('emisor.id')
    * def idReceptor = store.getString('receptor.id')
    And assert codigoReferencia != null

    Given url adminUrl
    And path 'admin', 'v1', 'transactions'
    And header Authorization = 'Bearer ' + tokenAdmin
    When method get
    Then status 200
    And match response == '#[_ > 0]'

    * def movimientos = karate.filter(response, function(t){ return t.referenceCode == codigoReferencia })
    And match movimientos == '#[2]'

    * def salida = karate.filter(movimientos, function(t){ return t.type == 'EXPENSE' })
    * def entrada = karate.filter(movimientos, function(t){ return t.type == 'INCOME' })
    And match salida == '#[1]'
    And match entrada == '#[1]'

    And match salida[0].userId == idEmisor
    And match entrada[0].userId == idReceptor
    And match salida[0].amount == montoTransferencia
    And match entrada[0].amount == montoTransferencia
    And assert salida[0].id != entrada[0].id

    * print '>> Movimiento de salida:', salida[0]
    * print '>> Movimiento de entrada:', entrada[0]


  @admin-saldos
  Scenario: Verificar los saldos finales de ambos usuarios en la vista administrativa

    * def idEmisor = store.getString('emisor.id')
    * def idReceptor = store.getString('receptor.id')
    * def saldoFinalEmisor = store.getDouble('emisor.saldoFinal')
    * def saldoFinalReceptor = store.getDouble('receptor.saldoFinal')

    Given url adminUrl
    And path 'admin', 'v1', 'users'
    And header Authorization = 'Bearer ' + tokenAdmin
    When method get
    Then status 200
    And match response == '#[_ > 0]'

    * def emisorAdmin = karate.filter(response, function(u){ return u.id == idEmisor })
    * def receptorAdmin = karate.filter(response, function(u){ return u.id == idReceptor })

    And match emisorAdmin == '#[1]'
    And match receptorAdmin == '#[1]'

    And match emisorAdmin[0] contains { balance: '#(saldoFinalEmisor)', status: 'ACTIVE' }
    And match receptorAdmin[0] contains { balance: '#(saldoFinalReceptor)', status: 'ACTIVE' }

    * print '>> Saldos confirmados en el backoffice | Emisor:', saldoFinalEmisor, '| Receptor:', saldoFinalReceptor
