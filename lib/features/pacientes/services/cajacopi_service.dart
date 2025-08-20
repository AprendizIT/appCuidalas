import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/validacion_tamizaje.dart';

/// Servicio para consultar el estado de afiliación en Cajacopi EPS
class CajacopiService {
  static const String _baseUrl =
      'https://genesis.cajacopieps.com/php/consultaAfiliados/obtenerafiliadoips.php';

  /// Consulta el estado de afiliación de un paciente
  /// Retorna un mapa con el estado y los datos del afiliado
  static Future<ValidacionCajacopi> consultarAfiliacion({
    required String tipoDocumento,
    required String numeroDocumento,
  }) async {
    try {
      print('🔍 Consultando afiliación en Cajacopi...');
      print('   Tipo documento: $tipoDocumento');
      print('   Número documento: $numeroDocumento');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'tipodocumento': tipoDocumento,
          'documento': numeroDocumento,
          'function': 'obtenerafiliados',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        print('📋 Respuesta de Cajacopi: ${result.toString()}');

        // Verificar si el afiliado no existe
        if (result['CODIGO']?.toString() == '1') {
          print('❌ Afiliado no existe en Cajacopi');
          return ValidacionCajacopi.noExiste();
        }

        // Extraer información del afiliado
        final estado = result['ESTADO'] ?? 'DESCONOCIDO';
        final regimen = result['REGIMEN'] ?? '';

        print('✅ Afiliado encontrado:');
        print('   Estado: $estado');
        print('   Régimen: $regimen');

        final map = {
          'existe': true,
          'estado': estado,
          'regimen': regimen,
          'activo': estado == 'ACTIVO',
          'datos': result,
          'mensaje': null,
        };
        return ValidacionCajacopi.fromJson(map);
      } else {
        print('❌ Error en la consulta: ${response.statusCode}');
        return ValidacionCajacopi.error('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error consultando Cajacopi: $e');
      return ValidacionCajacopi.error('No se pudo validar el estado de afiliación: $e');
    }
  }

  /// Nota: la lógica de mensajes se centraliza en ValidacionCajacopi.
}