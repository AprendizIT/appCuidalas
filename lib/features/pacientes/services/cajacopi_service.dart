import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para consultar el estado de afiliación en Cajacopi EPS
class CajacopiService {
  static const String _baseUrl =
      'https://genesis.cajacopieps.com/php/consultaAfiliados/obtenerafiliadoips.php';

  /// Consulta el estado de afiliación de un paciente
  /// Retorna un mapa con el estado y los datos del afiliado
  static Future<Map<String, dynamic>> consultarAfiliacion({
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

        // Verificar si el afiliado no existe
        if (result['CODIGO']?.toString() == '1') {
          print('❌ Afiliado no existe en Cajacopi');
          return {
            'existe': false,
            'estado': 'NO EXISTE',
            'mensaje':
                'El usuario no existe en la base de datos de Cajacopi EPS',
          };
        }

        // Extraer información del afiliado
        final estado = result['ESTADO'] ?? 'DESCONOCIDO';
        final regimen = result['REGIMEN'] ?? '';

        print('✅ Afiliado encontrado:');
        print('   Estado: $estado');
        print('   Régimen: $regimen');

        return {
          'existe': true,
          'estado': estado,
          'regimen': regimen,
          'activo': estado == 'ACTIVO',
          'datos': result,
          'mensaje': _getMensajeEstado(estado),
        };
      } else {
        print('❌ Error en la consulta: ${response.statusCode}');
        return {
          'existe': false,
          'estado': 'ERROR',
          'mensaje': 'Error al consultar el servicio de Cajacopi',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Error consultando Cajacopi: $e');
      return {
        'existe': false,
        'estado': 'ERROR',
        'mensaje': 'No se pudo validar el estado de afiliación',
        'error': e.toString(),
      };
    }
  }

  /// Obtiene un mensaje descriptivo según el estado
  static String _getMensajeEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return 'Afiliación activa en Cajacopi EPS';
      case 'INACTIVO':
        return 'El usuario no se encuentra activo en Cajacopi EPS';
      case 'SUSPENDIDO':
        return 'La afiliación se encuentra suspendida';
      case 'RETIRADO':
        return 'El usuario está retirado de Cajacopi EPS';
      case 'NO EXISTE':
        return 'El usuario no existe en la base de datos';
      case 'ERROR':
        return 'Error al validar el estado de afiliación';
      default:
        return 'Estado de afiliación: $estado';
    }
  }

  /// Mapea el tipo de documento para la API de Cajacopi
  static String mapearTipoDocumento(String tipoDoc) {
    // Mapear según los códigos que maneja Cajacopi
    // Estos valores deben ajustarse según la API real
    final tipoUpper = tipoDoc.toUpperCase();

    if (tipoUpper.contains('CEDULA') || tipoUpper.contains('CC')) {
      return 'CC';
    } else if (tipoUpper.contains('TARJETA') || tipoUpper.contains('TI')) {
      return 'TI';
    } else if (tipoUpper.contains('REGISTRO') || tipoUpper.contains('RC')) {
      return 'RC';
    } else if (tipoUpper.contains('PASAPORTE') || tipoUpper.contains('PA')) {
      return 'PA';
    } else if (tipoUpper.contains('EXTRANJERIA') || tipoUpper.contains('CE')) {
      return 'CE';
    }

    // Por defecto retornar el valor original
    return tipoDoc;
  }
}
