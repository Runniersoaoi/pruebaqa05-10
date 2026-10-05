/**
 * Configuracion global de la suite.
 *
 * Se ejecuta antes de cada escenario y entrega las variables comunes:
 * URLs por microservicio, el header obligatorio x-channel, los datos de
 * negocio del examen y las funciones reutilizables.
 */
function fn() {

  var env = karate.env || 'dev';
  karate.log('>> Entorno de ejecucion:', env);

  var host = 'http://134.209.211.10';

  var config = {

    env: env,

    // Un microservicio por puerto, segun la documentacion OpenAPI
    authUrl:        host + ':4001',   // Auth Service
    walletUrl:      host + ':4002',   // Wallet Service
    transactionUrl: host + ':4003',   // Transaction Service
    adminUrl:       host + ':4004',   // Admin Service

    // Header obligatorio en TODAS las peticiones.
    // Si falta o lleva un valor no permitido, la API responde 400 con GEN_001.
    channel: 'POSTMAN',
    adminChannel: 'ADMIN',

    // Datos de negocio definidos por el enunciado
    pinPorDefecto: '123456',
    montoDeposito: 1000.00,
    montoTransferencia: 450.00,
    notaTransferencia: 'Pago de Servicios',

    // Credenciales del backoffice administrativo
    adminUser: {
      username: 'admin',
      password: 'superpassword'
    }
  };

  // Almacen global compartido entre escenarios (ver utils/GlobalStore.java)
  config.store = Java.type('utils.GlobalStore').getInstance();

  /**
   * Genera un numero de celular peruano valido: 9 digitos que empiezan en 9.
   * Cada ejecucion crea usuarios nuevos, de modo que la suite es repetible
   * sin tener que limpiar datos entre corridas.
   */
  config.generarCelular = function () {
    var numero = '9';
    for (var i = 0; i < 8; i++) {
      numero = numero + Math.floor(Math.random() * 10);
    }
    return numero;
  };

  /** Deriva un correo unico a partir del celular generado. */
  config.generarEmail = function (celular) {
    return 'qa.' + celular + '@correo-prueba.com';
  };

  karate.configure('connectTimeout', 20000);
  karate.configure('readTimeout', 20000);

  return config;
}
