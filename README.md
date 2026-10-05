# Examen Practico de Karate - Billetera Digital Enterprise

Suite de pruebas automatizadas de API con **Karate 1.4.1** sobre la plataforma
Billetera Digital Enterprise (4 microservicios).

## Como ejecutar

```bash
mvn clean test
```

O desde IntelliJ: clic derecho sobre `runner/ExamenRunnerTest.java` -> Run.

El reporte HTML queda en:

```
target/karate-reports/karate-summary.html
```

Para el PDF que pide el examen: abrir ese HTML en Chrome -> Imprimir -> Guardar como PDF.

## Estructura

```
src/test/java/
├── karate-config.js                 Configuracion global: URLs, x-channel, store y utilidades
├── utils/GlobalStore.java           Almacen compartido entre escenarios
├── runner/ExamenRunnerTest.java     Runner JUnit 5 (un solo hilo, orden garantizado)
└── features/
    ├── regresion.feature            Escenarios 1, 2 y 3
    ├── administrador.feature        Feature 3: flujo administrativo
    └── comun/
        ├── crear-usuario-con-saldo.feature   Alta de usuario reutilizable
        └── login-admin.feature               Token de superusuario reutilizable
```

## Microservicios

| Servicio    | Puerto | Uso en la suite                          |
|-------------|--------|------------------------------------------|
| Auth        | 4001   | Registro y login de Emisor y Receptor    |
| Wallet      | 4002   | Deposito y consulta de saldos            |
| Transaction | 4003   | Transferencia de 450.00                  |
| Admin       | 4004   | Auditoria de la transaccion              |

Todas las peticiones envian el header obligatorio `x-channel`; si falta,
la API responde `400` con el codigo `GEN_001`.

## Como se comparte el estado entre escenarios

Karate entrega a cada escenario una **copia** de las variables, de modo que lo
definido en un escenario no es visible en el siguiente. El examen exige
justamente lo contrario: comparar los saldos del Escenario 2 y 3 contra los
capturados en el Escenario 1.

La solucion es `utils/GlobalStore.java`, un singleton expuesto en
`karate-config.js` como la variable `store`. Los objetos Java se pasan **por
referencia**, no se clonan, asi que el estado sobrevive durante toda la
ejecucion de la JVM.

```gherkin
# Escenario 1 escribe
* eval store.set('emisor.saldoInicial', emisor.saldoInicial)

# Escenario 2 lee
* def saldoInicialEmisor = store.getDouble('emisor.saldoInicial')
```

Por eso el runner usa `parallel(1)`: los tres escenarios son dependientes
entre si y deben correr en orden, en una sola ejecucion.
