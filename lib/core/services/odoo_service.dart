import 'package:odoo_rpc/odoo_rpc.dart';
import '../config/environment_config.dart';

class OdooService {
  static OdooClient? _client;
  static bool _isConnected = false;

  // Configuración de la conexión usando variables de entorno
  static String get _baseUrl => EnvironmentConfig.odooUrl;
  static String get _database => EnvironmentConfig.odooDatabase;
  static String get _username => EnvironmentConfig.username;
  static String get _password => EnvironmentConfig.password;

  /// Inicializa la conexión con Odoo
  static Future<bool> init() async {
    try {
      print('🚀 Conectando con Odoo...');

      // Mostrar detalles de conexión (sin password) para debugging
      print(
          '🔧 Odoo config -> url: ${_baseUrl}, db: ${_database}, user: ${_username}');

      _client = OdooClient(_baseUrl);

      await _client!.authenticate(
        _database,
        _username,
        _password,
      );

      _isConnected = true;
      print('✅ Conexión exitosa');

      // Diagnóstico rápido: comprobar permisos y existencia de datos
      try {
        final patientCount = await searchCount('hms.patient');
        print('🔢 hms.patient count: $patientCount');
        final samplePatients = await searchRead(
          'hms.patient',
          domain: [],
          fields: ['id', 'name', 'vat', 'partner_id'],
          limit: 5,
        );
        print('🧾 sample hms.patient: $samplePatients');
      } catch (e) {
        print('⚠️ No se puede leer hms.patient: $e');
      }
      return _isConnected;
    } catch (e) {
      print('❌ Error conectando: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Verifica si hay conexión activa
  static bool get isConnected => _isConnected && _client != null;

  /// Obtiene el cliente Odoo (requiere init() previo)
  static OdooClient get client {
    if (!isConnected) {
      throw Exception(
          'Odoo no está conectado. Llama a OdooService.init() primero.');
    }
    return _client!;
  }

  /// Busca registros en un modelo
  static Future<List<dynamic>> searchRead(
    String model, {
    List<dynamic> domain = const [],
    List<String> fields = const [],
    int limit = 0,
    int offset = 0,
  }) async {
    if (!isConnected) {
      throw Exception('No hay conexión con Odoo');
    }

    try {
      // Envío único y explícito: domain en kwargs (recomendado para compatibilidad)
      final payload = {
        'model': model,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': domain,
          'fields': fields,
          'limit': limit,
          'offset': offset,
        },
      };
      print('➡️ Payload de search_read de Odoo: $payload');
      final result = await _client!.callKw(payload);
      if (result == null) return <dynamic>[];
      return List<dynamic>.from(result as List);
    } catch (e) {
      print('Error en searchRead: $e');
      rethrow;
    }
  }

  /// Cuenta registros en un modelo
  static Future<int> searchCount(
    String model, {
    List<dynamic> domain = const [],
  }) async {
    if (!isConnected) {
      throw Exception('No hay conexión con Odoo');
    }

    try {
      final result = await _client!.callKw({
        'model': model,
        'method': 'search_count',
        'args': [],
        'kwargs': {
          'domain': domain,
        },
      });

      return result as int;
    } catch (e) {
      print('Error en searchCount: $e');
      rethrow;
    }
  }

  /// Realiza una búsqueda (search) y devuelve lista de ids
  static Future<List<int>> search(
    String model, {
    List<dynamic> domain = const [],
    int limit = 0,
    int offset = 0,
  }) async {
    if (!isConnected) {
      throw Exception('No hay conexión con Odoo');
    }

    try {
      final payload = {
        'model': model,
        'method': 'search',
        'args': [domain],
        'kwargs': {
          'limit': limit,
          'offset': offset,
        },
      };
      print('➡️ Odoo search payload: $payload');
      final result = await _client!.callKw(payload);
      return List<int>.from(result as List);
    } catch (e) {
      print('Error en search: $e');
      rethrow;
    }
  }

  /// Obtiene metadatos de campos de un modelo (fields_get)
  static Future<Map<String, dynamic>> fieldsGet(String model) async {
    if (!isConnected) {
      throw Exception('No hay conexión con Odoo');
    }

    try {
      final result = await _client!.callKw({
        'model': model,
        'method': 'fields_get',
        'args': [],
        'kwargs': {
          'attributes': ['string', 'type', 'help']
        },
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      print('Error en fieldsGet($model): $e');
      rethrow;
    }
  }

  /// Cierra la conexión
  static Future<void> disconnect() async {
    try {
      _client?.close();
    } catch (e) {
      print('Error cerrando conexión Odoo: $e');
    } finally {
      _client = null;
      _isConnected = false;
    }
  }
}
