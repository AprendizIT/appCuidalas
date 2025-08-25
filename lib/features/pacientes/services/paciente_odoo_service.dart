import '../../../core/services/odoo_service.dart';
import '../models/paciente.dart';

class PacienteOdooService {
  // Normaliza valores que pueden venir de Odoo
  static String _normalizeDescription(dynamic v) {
    if (v == null) return '';
    if (v is bool) return '';
    final s = v.toString();
    return s.trim();
  }
  
  /// Busca UN paciente específico por documento que tenga citas de tamizaje
  /// Usa el método optimizado de Odoo
  static Future<Paciente?> buscarPorDocumento(String numeroDocumento) async {
    try {
      print('Buscando paciente tamizaje con documento: $numeroDocumento');

      if (!OdooService.isConnected) {
        final connected = await OdooService.init();
        if (!connected) {
          throw Exception('No se pudo conectar con Odoo');
        }
      }

      // Usar el método optimizado de Odoo
      final response = await OdooService.client.callKw({
        'model': 'hms.appointment',
        'method': 'get_paciente_por_procedimiento',
        'args': [[], numeroDocumento.trim(), 13],
        'kwargs': {},
      });

      if (response == null) return null;

      // Verificar recordset vacío
      final responseStr = response.toString();
      if (responseStr.contains('hms.patient()') || !responseStr.contains('hms.patient(')) {
        return null;
      }

      // Extraer ID del paciente
      final match = RegExp(r'hms\.patient\((\d+)').firstMatch(responseStr);
      if (match?.group(1) == null) return null;

      final patientId = int.tryParse(match!.group(1)!);
      if (patientId == null) return null;

      // Obtener datos completos del paciente con tipo de documento
      return await _obtenerPacienteCompleto(patientId);
    } catch (e) {
      print('Error buscando paciente: $e');
      return null;
    }
  }

  /// Obtiene un paciente completo con datos del tipo de documento
  /// Una consulta optimizada
  static Future<Paciente?> _obtenerPacienteCompleto(int patientId) async {
    try {
      // Consulta principal del paciente
      final patientResults = await OdooService.searchRead(
        'hms.patient',
        domain: [['id', '=', patientId]],
        fields: [
          'id', 'name', 'vat', 'edad_anhos', 'eps', 'mobile', 'email',
          'l10n_latam_identification_type_id',
        ],
        limit: 1,
      );

      if (patientResults.isEmpty) return null;

      final patientData = patientResults.first as Map<String, dynamic>;
      
      // Obtener tipo de documento si existe
      String tipoDescription = '';
      String tipoNombre = '';
      
      final tipoField = patientData['l10n_latam_identification_type_id'];
      if (tipoField is List && tipoField.length > 1) {
        tipoNombre = tipoField[1].toString();
        
        final tipoResults = await OdooService.searchRead(
          'l10n_latam.identification.type',
          domain: [['id', '=', tipoField[0]]],
          fields: ['description', 'l10n_co_document_code'],
          limit: 1,
        );
        
        if (tipoResults.isNotEmpty) {
          final tipoData = tipoResults.first as Map<String, dynamic>;
          tipoDescription = _normalizeDescription(
            tipoData['description'] ?? tipoData['l10n_co_document_code']
          );
        }
      }

      var paciente = _mapearPaciente(patientData, tipoDescription, tipoNombre);
      
      // Consultar último examen
      return await _consultarUltimoExamen(paciente);
    } catch (e) {
      print('Error obteniendo paciente completo: $e');
      return null;
    }
  }

  /// Consulta el último examen (simplificado)
  static Future<Paciente> _consultarUltimoExamen(Paciente paciente) async {
    try {
      final tipoParaConsulta = paciente.tipoIdentificacion.isNotEmpty 
          ? paciente.tipoIdentificacion : 'CC';

      final response = await OdooService.client.callKw({
        'model': 'hms.appointment',
        'method': 'validar_ultima_cita_bot',
        'args': [[], tipoParaConsulta, paciente.cedula, 13],
        'kwargs': {},
      });

      bool tuvoExamenReciente = false;
      DateTime? fechaUltimoExamen;
      
      if (response != null) {
        final responseStr = response.toString();
        
        if (responseStr.contains('hms.appointment(') && responseStr.contains(',)')) {
          final match = RegExp(r'hms\.appointment\((\d+)').firstMatch(responseStr);
          
          if (match?.group(1) != null) {
            tuvoExamenReciente = true;
            final appointmentId = int.tryParse(match!.group(1)!);
            
            if (appointmentId != null) {
              fechaUltimoExamen = await _obtenerFechaUltimoExamen(appointmentId);
            }
          }
        }
      }

      return paciente.copyWith(
        ultimoExamenReciente: tuvoExamenReciente,
        fechaUltimoExamen: fechaUltimoExamen,
      );
    } catch (e) {
      print('Error consultando último examen: $e');
      return paciente;
    }
  }

  /// Obtiene fecha del último examen
  static Future<DateTime?> _obtenerFechaUltimoExamen(int appointmentId) async {
    try {
      final appointments = await OdooService.searchRead(
        'hms.appointment',
        domain: [['id', '=', appointmentId]],
        fields: ['date', 'create_date'],
        limit: 1,
      );
      
      if (appointments.isNotEmpty) {
        final appointment = appointments.first as Map<String, dynamic>;
        final dateStr = appointment['date'] ?? appointment['create_date'];
        
        if (dateStr != null) {
          return DateTime.parse(dateStr.toString());
        }
      }
    } catch (e) {
      print('Error obteniendo fecha del examen: $e');
    }
    return null;
  }

  /// Mapea datos a modelo Paciente (simplificado)
  static Paciente _mapearPaciente(
    Map<String, dynamic> data, 
    String tipoDescription,
    String tipoNombre,
  ) {
    // EPS validation
    bool afiliacionActiva = false;
    final eps = data['eps'];
    if (eps != null) {
      afiliacionActiva = eps.toString().toLowerCase().contains('cajacopi eps s.a.s.');
    }

    // Age extraction
    int edad = 0;
    final edadField = data['edad_anhos'];
    if (edadField is int) {
      edad = edadField;
    } else if (edadField is String) {
      edad = int.tryParse(edadField) ?? 0;
    }

    return Paciente(
      cedula: data['vat']?.toString() ?? '',
      nombreCompleto: data['name']?.toString() ?? 'Sin nombre registrado',
      edad: edad,
      telefono: data['mobile']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      afiliacionActiva: afiliacionActiva,
      fechaUltimoExamen: null,
      tipoIdentificacion: tipoDescription,
      tipoIdentificacionDescripcion: tipoDescription,
      tipoIdentificacionNombre: tipoNombre.isNotEmpty ? tipoNombre : null,
    );
  }
}