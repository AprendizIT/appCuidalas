import 'dart:convert';
import '../../../core/services/odoo_service.dart'; // Asegúrate de que la ruta sea correcta.
import '../models/validacion_tamizaje.dart';

/// Servicio para consultar el estado de afiliación en Cajacopi EPS
class CajacopiService {
  static Future<ValidacionCajacopi> consultarAfiliacion({
    required String tipoDocumento,
    required String numeroDocumento,
  }) async {
    try {
      print('🔍 Consultando afiliación en Cajacopi...');
      print('   Tipo documento: $tipoDocumento');
      print('   Número documento: $numeroDocumento');

      // Llamada al método de Odoo
      final result = await OdooService.client.callKw({
        'model': 'hms.appointment', // Modelo relevante de Odoo
        'method': 'get_status_afiliacion_result', // Método a invocar en Odoo
        'args': [
          [], // Lista vacía de IDs porque no necesitamos un registro específico
          tipoDocumento, 
          numeroDocumento
        ],
        'kwargs': {}
      });

      // Procesar la respuesta de Odoo
      final estado = result[0]; // Estado retornado por Odoo
      final datosAfiliado = result[1]; // Datos completos del afiliado

      if (estado == "ERROR") {
        print('❌ Error: No se pudo validar el estado de afiliación');
        return ValidacionCajacopi.error("No se pudo validar el estado de afiliación");
      }

      // Si el afiliado no existe, retorna el estado 'No Existe'
      if (estado == "NO EXISTE") {
        print('❌ Afiliado no existe');
        return ValidacionCajacopi.noExiste();
      }

      // Validar que datosAfiliado no sea nulo o vacío antes de acceder a sus campos
      if (datosAfiliado == null || datosAfiliado == "") {
        print('⚠️ Datos del afiliado vacíos');
        return ValidacionCajacopi.error("Datos del afiliado no disponibles");
      }

      final regimen = datosAfiliado['REGIMEN'] ?? ''; // Regimen del afiliado
      final map = {
        'existe': true,
        'estado': estado,
        'regimen': regimen,
        'activo': estado == 'ACTIVO',
        'datos': datosAfiliado,
        'mensaje': null,
      };

      print('✅ Afiliado encontrado:');
      print('   Estado: $estado');
      print('   Régimen: $regimen');
      print('   Activo: ${estado == 'ACTIVO' ? 'Sí' : 'No'}');

      return ValidacionCajacopi.fromJson(map);

    } catch (e) {
      print('💥 Error consultando Cajacopi: $e');
      return ValidacionCajacopi.error("No se pudo validar el estado de afiliación: ${e.toString()}");
    }
  }
}