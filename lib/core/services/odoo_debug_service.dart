import '../../../core/services/odoo_service.dart';

/// Servicio de debug para investigar la estructura del modelo hms.patient
class OdooDebugService {
  /// Lista todos los campos disponibles del modelo hms.patient
  static Future<void> listarCamposModelo() async {
    try {
      if (!OdooService.isConnected) {
        await OdooService.init();
      }

      print('🔍 Listando campos del modelo hms.patient...');

      final result = await OdooService.client.callKw({
        'model': 'ir.model.fields',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': [
            ['model', '=', 'hms.patient']
          ],
          'fields': ['name', 'field_description', 'ttype'],
          'limit': 50,
        },
      });

      print('📋 Campos disponibles en hms.patient:');
      for (final field in result) {
        print(
            '  • ${field['name']} (${field['ttype']}) - ${field['field_description']}');
      }
    } catch (e) {
      print('❌ Error listando campos: $e');
    }
  }

  /// Busca pacientes sin filtros para ver qué datos están disponibles
  static Future<void> listarPacientesMuestra() async {
    try {
      if (!OdooService.isConnected) {
        await OdooService.init();
      }

      print('🔍 Obteniendo muestra de pacientes...');

      final results = await OdooService.searchRead(
        'hms.patient',
        domain: [], // Sin filtros
        fields: [
          'id',
          'name',
          'vat',
          'identification_code', // Campo alternativo posible
          'ref', // Campo alternativo posible
          'edad_anhos',
          'eps',
          'mobile',
          'email',
        ],
        limit: 5,
      );

      print('📊 Encontrados ${results.length} pacientes de muestra:');
      for (int i = 0; i < results.length; i++) {
        print('  🧑 Paciente ${i + 1}:');
        final patient = results[i];
        patient.forEach((key, value) {
          print('    $key: $value');
        });
        print('  ───────────────────');
      }
    } catch (e) {
      print('❌ Error obteniendo muestra: $e');
    }
  }

  /// Busca paciente por múltiples campos de cédula
  static Future<void> buscarPorVarioscampos(String cedula) async {
    try {
      if (!OdooService.isConnected) {
        await OdooService.init();
      }

      print('🔍 Buscando cédula $cedula en múltiples campos...');

      // Campos posibles donde podría estar la cédula
      final camposPosibles = [
        'vat',
        'identification_code',
        'ref',
        'partner_id.vat'
      ];

      for (final campo in camposPosibles) {
        print('🔎 Buscando en campo: $campo');

        try {
          final results = await OdooService.searchRead(
            'hms.patient',
            domain: [
              [campo, '=', cedula]
            ],
            fields: ['id', 'name', campo],
            limit: 1,
          );

          if (results.isNotEmpty) {
            print('✅ ¡Encontrado en $campo!');
            print('📋 Datos: ${results.first}');
            return;
          } else {
            print('❌ No encontrado en $campo');
          }
        } catch (e) {
          print('⚠️ Error buscando en $campo: $e');
        }
      }

      print('🔍 Buscando con operador "ilike" (búsqueda parcial)...');
      final results = await OdooService.searchRead(
        'hms.patient',
        domain: [
          '|',
          ['vat', 'ilike', cedula],
          ['name', 'ilike', cedula],
        ],
        fields: ['id', 'name', 'vat'],
        limit: 3,
      );

      if (results.isNotEmpty) {
        print(
            '✅ Encontrados ${results.length} registros con búsqueda parcial:');
        for (final result in results) {
          print('  📋 ${result}');
        }
      } else {
        print('❌ No se encontraron registros con búsqueda parcial');
      }
    } catch (e) {
      print('❌ Error en búsqueda múltiple: $e');
    }
  }
}
