// Configuración de entorno para desarrollo
// NUNCA commitear este archivo con credenciales reales
class EnvironmentConfig {
  // === CONFIGURACIÓN ODOO ===
  static const String odooUrl = String.fromEnvironment(
    'ODOO_URL',
    defaultValue: 'https://healthgroup-test2-22479070.dev.odoo.com',
  );

  static const String odooDatabase = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: 'healthgroup-test2-22479070',
  );

  static const String odooUsername = String.fromEnvironment(
    'ODOO_USERNAME',
    defaultValue: '',
  );

  static const String odooPassword = String.fromEnvironment(
    'ODOO_PASSWORD',
    defaultValue: '',
  );

  // === CONFIGURACIÓN CAJACOPI API ===
  static const String cajacopiApiUrl = String.fromEnvironment(
    'CAJACOPI_API_URL',
    defaultValue:
        'https://genesis.cajacopieps.com/php/consultaAfiliados/obtenerafiliadoips.php',
  );

  // Timeout para las consultas a CajaCopi (en segundos)
  static const int cajacopiTimeout = 30;

  // === VALIDACIÓN DE CREDENCIALES ===
  static bool get areCredentialsConfigured {
    return odooUsername.isNotEmpty && odooPassword.isNotEmpty;
  }

  // Para desarrollo temporal - ELIMINAR en producción
  static const String _devUsername = 'danieltest@flutter.com';
  static const String _devPassword = 'danieltest123';

  static String get username =>
      odooUsername.isNotEmpty ? odooUsername : _devUsername;
  static String get password =>
      odooPassword.isNotEmpty ? odooPassword : _devPassword;
}
