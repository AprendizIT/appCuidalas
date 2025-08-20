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
      
      // Campos a obtener, incluyendo el description del tipo de documento
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
      
      // Ahora necesitamos obtener el description del tipo de documento
      // usando la notación de punto como en Odoo Python
      String tipoDocumentoDescription = ''; // Default vacío -> no mostrar si no existe
      String tipoDocumentoNombre = '';
      
      if (data['l10n_latam_identification_type_id'] != null) {
        final tipoField = data['l10n_latam_identification_type_id'];
        
        // El campo viene como [id, "name"]
        if (tipoField is List && tipoField.length > 1) {
          final tipoId = tipoField[0];
          tipoDocumentoNombre = tipoField[1].toString();
          
          // Ahora obtenemos el description del tipo de documento
          try {
            final tipoDocResults = await OdooService.searchRead(
              'l10n_latam.identification.type',
              domain: [['id', '=', tipoId]],
              fields: ['id', 'name', 'description'],
              limit: 1,
            );
            
            if (tipoDocResults.isNotEmpty) {
              final tipoDocData = tipoDocResults.first as Map<String, dynamic>;
              // Normalizar: evitar 'false' si el campo viene como boolean
              tipoDocumentoDescription = _normalizeDescription(tipoDocData['description'] ?? tipoDocData['l10n_co_document_code'] ?? tipoDocData['code']);
              if (tipoDocumentoDescription.isEmpty) tipoDocumentoDescription = '';
              print('📄 Tipo documento description obtenido: $tipoDocumentoDescription');
            }
          } catch (e) {
            print('⚠️ No se pudo obtener el description del tipo de documento: $e');
          }
        }
      }
      
      print('✅ Paciente encontrado');
      print('   Tipo documento description: $tipoDocumentoDescription');
      print('   Tipo documento nombre: $tipoDocumentoNombre');
      
      final paciente = _mapearPacienteDesdeOdoo(data, tipoDocumentoDescription, tipoDocumentoNombre);
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

      // Para cada resultado, obtener el tipo de documento
      // Para cada resultado, obtener el tipo de documento
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
                fields: ['id', 'l10n_co_document_code'],
                limit: 1,
              );
              
              if (tipoDocResults.isNotEmpty) {
                final tipoDocData = tipoDocResults.first as Map<String, dynamic>;
                tipoDescription = _normalizeDescription(tipoDocData['l10n_co_document_code']);
                if (tipoDescription.isEmpty) tipoDescription = '';
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