import 'dart:convert';

import '../../../core/services/odoo_service.dart';
import '../models/paciente.dart';

class PacienteOdooService {
  /// Busca un paciente por cédula en el modelo hms.patient
  /// tipoDocumento: código abreviado (CC, TI, PA, etc.) utilizado para
  /// ajustar la estrategia de búsqueda (igualdad para numéricos, ilike para alfanuméricos)
  static Future<Paciente?> buscarPorCedula(String cedula, {String tipoDocumento = 'CC'}) async {
    try {
      print('🔍 Buscando paciente con cédula: $cedula (tipo: $tipoDocumento)');

      // Asegurar conexión
      if (!OdooService.isConnected) {
        print('🔌 Conectando con Odoo...');
        final connected = await OdooService.init();
        if (!connected) {
          print('❌ No se pudo conectar con Odoo');
          throw Exception('No se pudo conectar con Odoo');
        }
        print('✅ Conexión establecida');
      }

      final cedulaTrim = cedula.trim();
      final digitsOnly = cedulaTrim.replaceAll(RegExp(r'\D'), '');
      final fields = [
        'id',
        'name',
        'vat',
        'edad_anhos',
        'eps',
        'mobile',
        'email',
        'l10n_latam_identification_type_id',
      ];

      // Construir dominio según tipo de documento
      final domainAttempts = <List<dynamic>>[];
      final tipoUpper = tipoDocumento.toUpperCase();

      // Para tipos numéricos hacemos búsqueda de igualdad sobre vat (trimmed digits)
      final numericTypes = {'CC', 'TI', 'RC', 'NIT', 'CE'};
      if (numericTypes.contains(tipoUpper)) {
        if (digitsOnly.isEmpty) {
          print('⚠️ Cédula no contiene dígitos: $cedulaTrim');
          return null;
        }
        domainAttempts.add([
          ['vat', '=', digitsOnly]
        ]);
      } else {
        // Para tipos alfanuméricos (pasaporte etc) usar ilike con el valor completo
        domainAttempts.add([
          ['vat', 'ilike', cedulaTrim]
        ]);
      }

      // Deduplicate domains
      final seen = <String>{};
      final dedupedDomains = <List<dynamic>>[];
      for (final d in domainAttempts) {
        try {
          final key = jsonEncode(d);
          if (!seen.contains(key)) {
            seen.add(key);
            dedupedDomains.add(d);
          }
        } catch (_) {
          dedupedDomains.add(d);
        }
      }

      List<dynamic> results = [];
      for (final domain in dedupedDomains) {
        print('🔎 Intentando dominio: $domain');
        try {
          results = await OdooService.searchRead(
            'hms.patient',
            domain: domain,
            fields: fields,
            limit: 1,
          );
        } catch (e) {
          print('⚠️ Error al consultar con dominio $domain: $e');
          results = [];
        }

        print('📊 Resultados para dominio $domain: ${results.length}');
        if (results.isNotEmpty) {
          print('🟢 Datos crudos Odoo: ${results.toString()}');
          break;
        }
      }

      // Fallback seguro para tipos numéricos: si no encontramos con '='
      // intentamos una búsqueda 'ilike' y luego filtramos localmente por igualdad
      // de los dígitos, esto permite manejar formatos con guiones/puntos.
      if (results.isEmpty && numericTypes.contains(tipoUpper)) {
        try {
          print('🔁 Intentando fallback ilike + filtrado local para: $digitsOnly');
          final alt = await OdooService.searchRead(
            'hms.patient',
            domain: [
              ['vat', 'ilike', digitsOnly]
            ],
            fields: fields,
            limit: 10,
          );

          final filtered = alt.where((record) {
            final vatRaw = (record['vat'] ?? '').toString();
            final vatDigits = vatRaw.replaceAll(RegExp(r'\D'), '');
            return vatDigits == digitsOnly;
          }).toList();

          if (filtered.isNotEmpty) {
            results = [filtered.first];
            print('🟢 Fallback produjo ${filtered.length} coincidencias, usando la primera');
          } else {
            print('⚪ Fallback no encontró coincidencias exactas tras filtrar por dígitos');
          }
        } catch (e) {
          print('⚠️ Error en fallback ilike: $e');
        }
      }

      if (results.isEmpty) {
        print('❌ No se encontró paciente con cédula: $cedula (todos los intentos)');
        return null;
      }

      final data = results.first as Map<String, dynamic>;
      final paciente = _mapearPacienteDesdeOdoo(data);
      print('✅ Paciente encontrado: ${paciente.nombreCompleto}');
      return paciente;
    } catch (e) {
      print('💥 Error buscando paciente: $e');
      return null;
    }
  }

  /// Mapea datos de Odoo al modelo Paciente local
  static Paciente _mapearPacienteDesdeOdoo(Map<String, dynamic> data) {
    // Validar EPS para determinar afiliación activa
    bool afiliacionActiva = false;
    final eps = data['eps'];
    if (eps != null) {
      final epsString = eps.toString().toLowerCase();
      afiliacionActiva = epsString.contains('cajacopi eps s.a.s.');
    }

    // Extraer edad
    int edad = 0;
    if (data['edad_anhos'] != null) {
      if (data['edad_anhos'] is int) {
        edad = data['edad_anhos'] as int;
      } else if (data['edad_anhos'] is String) {
        edad = int.tryParse(data['edad_anhos'] as String) ?? 0;
      }
    }

    // Extraer tipo de identificación
    String tipoIdentificacion = 'CC';
    if (data['l10n_latam_identification_type_id'] != null) {
      final tipoField = data['l10n_latam_identification_type_id'];
      if (tipoField is List && tipoField.length > 1) {
        final tipoDesc = tipoField[1].toString();
        tipoIdentificacion = _mapearTipoDocumento(tipoDesc);
      }
    }

    final cedula = data['vat']?.toString() ?? '';
    final nombre = data['name']?.toString() ?? '';
    final telefono = data['mobile']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';

    return Paciente(
      cedula: cedula,
      nombreCompleto: nombre.isNotEmpty ? nombre : 'Sin nombre registrado',
      edad: edad,
      telefono: telefono,
      email: email,
      afiliacionActiva: afiliacionActiva,
      fechaUltimoExamen: null,
      tipoIdentificacion: tipoIdentificacion,
    );
  }

  /// Mapea el tipo de documento de Odoo al formato esperado por CajaCopi
  static String _mapearTipoDocumento(String tipoOdoo) {
    final tipo = tipoOdoo.toUpperCase();

    if (tipo.contains('CÉDULA') || tipo.contains('CEDULA') || tipo.contains('CC')) return 'CC';
    if (tipo.contains('TARJETA') || tipo.contains('IDENTIDAD') || tipo.contains('TI')) return 'TI';
    if (tipo.contains('REGISTRO') || tipo.contains('CIVIL') || tipo.contains('RC')) return 'RC';
    if (tipo.contains('PASAPORTE') || tipo.contains('PA')) return 'PA';
    if (tipo.contains('EXTRANJERÍA') || tipo.contains('EXTRANJERIA') || tipo.contains('CE')) return 'CE';
    if (tipo.contains('NIT')) return 'NIT';

    final siglas = tipo.replaceAll(RegExp(r'[^A-Z]'), '');
    if (siglas.isNotEmpty && siglas.length <= 3) return siglas;

    print('⚠️ Tipo de documento no reconocido: $tipoOdoo, usando CC por defecto');
    return 'CC';
  }

  /// Busca pacientes con filtros múltiples
  static Future<List<Paciente>> buscarPacientes({
    String? nombre,
    String? cedula,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      if (!OdooService.isConnected) {
        final connected = await OdooService.init();
        if (!connected) {
          throw Exception('No se pudo conectar con Odoo');
        }
      }

      final domain = <List<dynamic>>[];
      if (nombre != null && nombre.isNotEmpty) domain.add(['name', 'ilike', nombre]);
      if (cedula != null && cedula.isNotEmpty) domain.add(['vat', 'ilike', cedula]);

      final results = await OdooService.searchRead(
        'hms.patient',
        domain: domain,
        fields: [
          'id',
          'name',
          'vat',
          'edad_anhos',
          'eps',
          'mobile',
          'email',
          'l10n_latam_identification_type_id',
        ],
        limit: limit,
        offset: offset,
      );

      return results.map((data) => _mapearPacienteDesdeOdoo(data as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error buscando pacientes: $e');
      return [];
    }
  }

  /// Cuenta total de pacientes
  static Future<int> contarPacientes() async {
    try {
      if (!OdooService.isConnected) {
        final connected = await OdooService.init();
        if (!connected) return 0;
      }
      return await OdooService.searchCount('hms.patient');
    } catch (e) {
      print('Error contando pacientes: $e');
      return 0;
    }
  }

  /// DEBUG: obtener algunos registros de hms.patient para inspeccionar estructura de campos
  static Future<void> debugMuestraRegistros() async {
    try {
      print('🛠️ Iniciando debug de registros en hms.patient');

      final sample = await OdooService.searchRead(
        'hms.patient',
        domain: [],
        fields: ['id', 'name', 'vat', 'l10n_latam_identification_type_id'],
        limit: 5,
      );
      print('🧾 Muestra de hms.patient (5): ${sample.toString()}');

      for (var record in sample) {
        if (record['l10n_latam_identification_type_id'] != null) {
          print('🆔 Tipo ID para ${record['name']}: ${record['l10n_latam_identification_type_id']}');
        }
      }
    } catch (e) {
      print('⚠️ No se pudo obtener muestra de hms.patient: $e');
    }
  }
}
