import 'validacion_tamizaje.dart';

class Paciente {
  final String cedula;
  final String nombreCompleto;
  final int edad;
  final String telefono;
  final String email;
  final bool afiliacionActiva;
  final DateTime? fechaUltimoExamen;
  final String tipoIdentificacion; // Description de Odoo (CC, TI, PT, etc)
  final String tipoIdentificacionDescripcion; // Mismo que tipoIdentificacion
  final String? tipoIdentificacionNombre; // Nombre completo del tipo
  final ValidacionCajacopi? validacionCajacopi;
  final bool ultimoExamenReciente; // true si tuvo examen en el último año
  final String? estadoUltimoExamen; // Estado del último examen si existe

  Paciente({
    required this.cedula,
    required this.nombreCompleto,
    required this.edad,
    this.telefono = '',
    this.email = '',
    required this.afiliacionActiva,
    this.fechaUltimoExamen,
    this.tipoIdentificacion = 'CC',
    this.tipoIdentificacionDescripcion = 'CC',
    this.tipoIdentificacionNombre,
    this.validacionCajacopi,
    this.ultimoExamenReciente = false,
    this.estadoUltimoExamen,
  });

  /// Verifica si el paciente es apto para agendar
  bool get esAptoParaAgendar {
    // Criterio 1: Edad entre 25 y 49 años
    if (edad < 25 || edad > 49) return false;

    // Criterio 2: Afiliación activa en Cajacopi (usar validación si existe)
    if (validacionCajacopi != null) {
      if (!validacionCajacopi!.esValido) return false;
    } else {
      // Si no hay validación de Cajacopi, usar el estado de Odoo
      if (!afiliacionActiva) return false;
    }

    // Criterio 3: Último examen hace más de 1 año (o nunca lo ha tenido)
    // Si hay un indicador explícito de último examen en el último año, no es apto
    if (ultimoExamenReciente) return false;
    
    return true;
  }

  /// Obtiene el motivo por el cual no es apto
  String get motivoNoApto {
    if (edad < 25 || edad > 49) {
      return 'La paciente debe tener entre 25 y 49 años. Edad actual: $edad años';
    }

    if (validacionCajacopi != null) {
      if (!validacionCajacopi!.esValido) {
        return validacionCajacopi!.mensaje;
      }
    } else if (!afiliacionActiva) {
      return 'La paciente debe estar afiliada activa en Cajacopi EPS';
    }

    if (ultimoExamenReciente) {
      if (fechaUltimoExamen != null) {
        final diferencia = DateTime.now().difference(fechaUltimoExamen!);
        final dias = diferencia.inDays;
        final meses = (dias / 30).floor();
        
        if (meses > 0) {
          return 'El último examen fue hace aproximadamente $meses ${meses == 1 ? 'mes' : 'meses'}';
        } else {
          return 'El último examen fue hace $dias ${dias == 1 ? 'día' : 'días'}';
        }
      }
      return 'El último examen fue hace menos de 1 año';
    }

    return 'No cumple con los criterios de elegibilidad';
  }

  /// Obtiene información detallada del último examen
  String? get infoUltimoExamen {
    if (fechaUltimoExamen == null) return null;
    
    final diferencia = DateTime.now().difference(fechaUltimoExamen!);
    final dias = diferencia.inDays;
    final meses = (dias / 30).floor();
    final anos = (dias / 365).floor();
    
    String tiempoTranscurrido;
    if (anos > 0) {
      tiempoTranscurrido = 'Hace $anos ${anos == 1 ? 'año' : 'años'}';
    } else if (meses > 0) {
      tiempoTranscurrido = 'Hace $meses ${meses == 1 ? 'mes' : 'meses'}';
    } else {
      tiempoTranscurrido = 'Hace $dias ${dias == 1 ? 'día' : 'días'}';
    }
    
    return tiempoTranscurrido;
  }

  /// Obtiene el nombre completo del tipo de documento o un valor por defecto
  String get nombreTipoDocumento {
    if (tipoIdentificacionNombre != null && tipoIdentificacionNombre!.isNotEmpty) {
      return tipoIdentificacionNombre!;
    }
    // Si no tenemos el nombre, retornar el código
    return tipoIdentificacion;
  }

  /// Obtiene la forma corta (sigla/description) para mostrar en la UI
  String get tipoDocumentoCorto {
    if (tipoIdentificacionDescripcion.isNotEmpty) return tipoIdentificacionDescripcion;
    if (tipoIdentificacion.isNotEmpty) return tipoIdentificacion;
    return '';
  }

  /// Indica si nunca ha tenido un examen
  bool get nuncaTuvoExamen => fechaUltimoExamen == null && !ultimoExamenReciente;

  /// Crea una copia del paciente con valores actualizados
  Paciente copyWith({
    String? cedula,
    String? nombreCompleto,
    int? edad,
    String? telefono,
    String? email,
    bool? afiliacionActiva,
    DateTime? fechaUltimoExamen,
    String? tipoIdentificacion,
    String? tipoIdentificacionDescripcion,
    String? tipoIdentificacionNombre,
    ValidacionCajacopi? validacionCajacopi,
    bool? ultimoExamenReciente,
    String? estadoUltimoExamen,
  }) {
    return Paciente(
      cedula: cedula ?? this.cedula,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      edad: edad ?? this.edad,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      afiliacionActiva: afiliacionActiva ?? this.afiliacionActiva,
      fechaUltimoExamen: fechaUltimoExamen ?? this.fechaUltimoExamen,
      tipoIdentificacion: tipoIdentificacion ?? this.tipoIdentificacion,
      tipoIdentificacionDescripcion: tipoIdentificacionDescripcion ?? this.tipoIdentificacionDescripcion,
      tipoIdentificacionNombre: tipoIdentificacionNombre ?? this.tipoIdentificacionNombre,
      validacionCajacopi: validacionCajacopi ?? this.validacionCajacopi,
      ultimoExamenReciente: ultimoExamenReciente ?? this.ultimoExamenReciente,
      estadoUltimoExamen: estadoUltimoExamen ?? this.estadoUltimoExamen,
    );
  }
}