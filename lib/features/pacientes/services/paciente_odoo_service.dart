import 'dart:convert';

import '../../../core/services/odoo_service.dart';
import '../models/paciente.dart';

class PacienteOdooService {
  // Normaliza valores que pueden venir de Odoo (evita 'false' o valores no deseados)
  static String _normalizeDescription(dynamic v) {
    if (v == null) return '';
    if (v is bool) return '';
    final s = v.toString();
    return s.trim();
  }
  
  /// Busca un paciente por número de documento en el modelo hms.patient
  static Future<Paciente?> buscarPorDocumento(String numeroDocumento) async {
    try {
      print('🔍 Buscando paciente con documento: $numeroDocumento');

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

      final documentoTrim = numeroDocumento.trim();
      
      // Campos a obtener
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

      // Buscar con ilike para ser más flexible con el formato
      print('🔎 Buscando con vat ilike: $documentoTrim');
      
      List<dynamic> results = await OdooService.searchRead(
        'hms.patient',
        domain: [
          ['vat', 'ilike', documentoTrim]
        ],
        fields: fields,
        limit: 10,
      );

      print('📊 Resultados encontrados: ${results.length}');

      // Si no encuentra con ilike, intentar búsqueda exacta
      if (results.isEmpty) {
        print('🔎 Intentando búsqueda exacta con vat =: $documentoTrim');
        results = await OdooService.searchRead(
          'hms.patient',
          domain: [
            ['vat', '=', documentoTrim]
          ],
          fields: fields,
          limit: 1,
        );
        print('📊 Resultados con búsqueda exacta: ${results.length}');
      }

      if (results.isEmpty) {
        print('❌ No se encontró paciente con documento: $numeroDocumento');
        return null;
      }

      final data = results.first as Map<String, dynamic>;
      
      // Obtener el description del tipo de documento
      String tipoDocumentoDescription = '';
      String tipoDocumentoNombre = '';
      
      if (data['l10n_latam_identification_type_id'] != null) {
        final tipoField = data['l10n_latam_identification_type_id'];
        
        if (tipoField is List && tipoField.length > 1) {
          final tipoId = tipoField[0];
          tipoDocumentoNombre = tipoField[1].toString();
          
          try {
            final tipoDocResults = await OdooService.searchRead(
              'l10n_latam.identification.type',
              domain: [['id', '=', tipoId]],
              fields: ['id', 'name', 'description', 'l10n_co_document_code'],
              limit: 1,
            );
            
            if (tipoDocResults.isNotEmpty) {
              final tipoDocData = tipoDocResults.first as Map<String, dynamic>;
              tipoDocumentoDescription = _normalizeDescription(
                tipoDocData['description'] ?? 
                tipoDocData['l10n_co_document_code']
              );
              print('📄 Tipo documento: $tipoDocumentoDescription');
            }
          } catch (e) {
            print('⚠️ Error obteniendo tipo de documento: $e');
          }
        }
      }
      
      print('✅ Paciente encontrado');
      var paciente = _mapearPacienteDesdeOdoo(data, tipoDocumentoDescription, tipoDocumentoNombre);

      // Consultar último examen usando el método de Odoo
      try {
        final tipoParaConsulta = tipoDocumentoDescription.isNotEmpty 
            ? tipoDocumentoDescription 
            : 'CC';
            
        print('🔎 Consultando último examen...');
        print('   Tipo: $tipoParaConsulta');
        print('   Identificación: ${paciente.cedula}');

        final payload = {
          'model': 'hms.appointment',
          'method': 'validar_ultima_cita_bot',
          'args': [
            [], // Lista vacía de IDs
            tipoParaConsulta,
            paciente.cedula,
            13, // procedimiento tamizaje
          ],
          'kwargs': {},
        };

        final response = await OdooService.client.callKw(payload);
        print('📨 Respuesta de validar_ultima_cita_bot: $response');

        // El método retorna un recordset de Odoo
        // hms.appointment() → Recordset vacío → NO hay citas en el último año → Paciente APTO
        // hms.appointment(ID,) → Recordset con registro → SÍ hay cita en el último año → Paciente NO APTO
        bool tuvoExamenReciente = false;
        DateTime? fechaUltimoExamen;
        
        if (response != null) {
          final responseStr = response.toString();
          print('📋 Analizando respuesta: $responseStr');
          
          // Verificar si el recordset tiene registros
          // hms.appointment() = vacío, hms.appointment(123,) = con registro
          if (responseStr.contains('hms.appointment(') && responseStr.contains(',)')) {
            // Extraer el ID del registro usando regex
            final match = RegExp(r'hms\.appointment\((\d+)').firstMatch(responseStr);
            
            if (match != null && match.group(1) != null) {
              // Hay un ID, significa que encontró una cita en el último año
              tuvoExamenReciente = true;
              print('❌ Paciente tuvo examen en el último año (no apto)');
              
              final appointmentId = int.tryParse(match.group(1)!);
              
              if (appointmentId != null) {
                try {
                  // Obtener detalles de la cita encontrada
                  final appointments = await OdooService.searchRead(
                    'hms.appointment',
                    domain: [['id', '=', appointmentId]],
                    fields: ['id', 'date', 'create_date', 'state'],
                    limit: 1,
                  );
                  
                  if (appointments.isNotEmpty) {
                    final appointment = appointments.first as Map<String, dynamic>;
                    
                    // Intentar obtener la fecha
                    final dateStr = appointment['date'] ?? appointment['create_date'];
                    if (dateStr != null) {
                      try {
                        fechaUltimoExamen = DateTime.parse(dateStr.toString());
                        print('📅 Fecha del último examen: $fechaUltimoExamen');
                      } catch (e) {
                        print('⚠️ No se pudo parsear la fecha: $e');
                      }
                    }
                  }
                } catch (e) {
                  print('⚠️ Error obteniendo detalles de la cita: $e');
                }
              }
            } else {
              // hms.appointment() sin ID = recordset vacío
              print('✅ No hay exámenes en el último año (apto si cumple otros criterios)');
            }
          } else if (responseStr.contains('hms.appointment()')) {
            // Recordset vacío explícito
            print('✅ No hay exámenes en el último año (apto si cumple otros criterios)');
          } else {
            // Respuesta inesperada
            print('⚠️ Respuesta inesperada del método: $responseStr');
          }
        } else {
          print('✅ No hay registro de exámenes previos (apto si cumple otros criterios)');
        }

        // Actualizar el paciente con la información del último examen
        paciente = paciente.copyWith(
          ultimoExamenReciente: tuvoExamenReciente,
          fechaUltimoExamen: fechaUltimoExamen,
        );
        
      } catch (e) {
        print('⚠️ Error consultando último examen: $e');
        // Continuar sin datos del último examen
      }

      return paciente;
    } catch (e) {
      print('💥 Error buscando paciente: $e');
      return null;
    }
  }

  /// Mapea datos de Odoo al modelo Paciente local
  static Paciente _mapearPacienteDesdeOdoo(
    Map<String, dynamic> data, 
    String tipoDocumentoDescription,
    String tipoDocumentoNombre
  ) {
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
      tipoIdentificacion: tipoDocumentoDescription,
      tipoIdentificacionDescripcion: tipoDocumentoDescription,
      tipoIdentificacionNombre: tipoDocumentoNombre.isNotEmpty ? tipoDocumentoNombre : null,
    );
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
      if (nombre != null && nombre.isNotEmpty) {
        domain.add(['name', 'ilike', nombre]);
      }
      if (cedula != null && cedula.isNotEmpty) {
        domain.add(['vat', 'ilike', cedula]);
      }

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

      final pacientes = <Paciente>[];
      
      for (final data in results) {
        String tipoDescription = '';
        String tipoNombre = '';
        
        if (data['l10n_latam_identification_type_id'] != null) {
          final tipoField = data['l10n_latam_identification_type_id'];
          if (tipoField is List && tipoField.length > 1) {
            final tipoId = tipoField[0];
            tipoNombre = tipoField[1].toString();
            
            try {
              final tipoDocResults = await OdooService.searchRead(
                'l10n_latam.identification.type',
                domain: [['id', '=', tipoId]],
                fields: ['id', 'description', 'l10n_co_document_code'],
                limit: 1,
              );
              
              if (tipoDocResults.isNotEmpty) {
                final tipoDocData = tipoDocResults.first as Map<String, dynamic>;
                tipoDescription = _normalizeDescription(
                  tipoDocData['description'] ?? 
                  tipoDocData['l10n_co_document_code']
                );
              }
            } catch (e) {
              print('⚠️ Error obteniendo tipo de documento: $e');
            }
          }
        }
        
        pacientes.add(_mapearPacienteDesdeOdoo(
          data as Map<String, dynamic>, 
          tipoDescription, 
          tipoNombre
        ));
      }

      return pacientes;
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
}