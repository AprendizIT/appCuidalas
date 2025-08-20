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

    // Criterio 3: Último examen hace 2 años o más
    if (fechaUltimoExamen != null) {
      final diferencia = DateTime.now().difference(fechaUltimoExamen!);
      if (diferencia.inDays < 730) return false; // Menos de 2 años
    }

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

    if (fechaUltimoExamen != null) {
      final diferencia = DateTime.now().difference(fechaUltimoExamen!);
      if (diferencia.inDays < 730) {
        return 'El último examen fue hace menos de 2 años';
      }
    }

    return 'No cumple con los criterios de elegibilidad';
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
    );
  }
}