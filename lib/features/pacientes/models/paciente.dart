import 'validacion_tamizaje.dart';

class Paciente {
  final String cedula;
  final String nombreCompleto;
  final int edad;
  final bool afiliacionActiva;
  final DateTime? fechaUltimoExamen;
  final String telefono;
  final String email;
  final EstadoCita? estadoCita;
  final DateTime? fechaProximaCita;

  // Nueva propiedad para guardar validación de CajaCopi
  final ValidacionCajacopi? validacionCajacopi;
  // Nuevo campo: tipo de identificación (CC, TI, PA, etc.)
  final String tipoIdentificacion;

  const Paciente({
    required this.cedula,
    required this.nombreCompleto,
    required this.edad,
    required this.afiliacionActiva,
    this.fechaUltimoExamen,
    required this.telefono,
    required this.email,
    this.estadoCita,
    this.fechaProximaCita,
    this.validacionCajacopi,
    this.tipoIdentificacion = 'CC',
  });

  bool get esAptoParaAgendar {
    // Primero verificar CajaCopi si está disponible
    if (validacionCajacopi != null && !validacionCajacopi!.esValido) {
      return false;
    }

    // Validaciones originales
    if (!afiliacionActiva) return false;
    if (edad < 25 || edad > 49) return false;
    if (fechaUltimoExamen != null) {
      final diferencia = DateTime.now().difference(fechaUltimoExamen!);
      if (diferencia.inDays < 365) return false; // Cambié a 1 año según el PDF
    }
    return estadoCita == null || estadoCita == EstadoCita.cancelado;
  }

  String get motivoNoApto {
    // Verificar primero CajaCopi
    if (validacionCajacopi != null) {
      if (!validacionCajacopi!.existe) {
        return 'No se encontró afiliación en Cajacopi EPS';
      }
      if (!validacionCajacopi!.activo) {
        return 'El paciente no tiene afiliación activa en Cajacopi (Estado: ${validacionCajacopi!.estado})';
      }
    }

    // Validaciones originales
    if (!afiliacionActiva) return 'No cuenta con afiliación activa';
    if (edad < 25)
      return 'Está fuera del rango de edad permitido (menor a 25 años)';
    if (edad > 49)
      return 'Está fuera del rango de edad permitido (mayor a 49 años)';
    if (fechaUltimoExamen != null) {
      final diferencia = DateTime.now().difference(fechaUltimoExamen!);
      if (diferencia.inDays < 365) {
        final meses = (diferencia.inDays / 30).round();
        return 'Ya se hizo el examen hace $meses meses';
      }
    }
    if (estadoCita != null && estadoCita != EstadoCita.cancelado) {
      return 'Cuenta con una cita en estado: ${estadoCita!.nombre}';
    }
    return '';
  }

  // Método para copiar con nuevos valores
  Paciente copyWith({
    String? cedula,
    String? nombreCompleto,
    int? edad,
    bool? afiliacionActiva,
    DateTime? fechaUltimoExamen,
    String? telefono,
    String? email,
    EstadoCita? estadoCita,
    DateTime? fechaProximaCita,
    ValidacionCajacopi? validacionCajacopi,
    String? tipoIdentificacion,
  }) {
    return Paciente(
      cedula: cedula ?? this.cedula,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      edad: edad ?? this.edad,
      afiliacionActiva: afiliacionActiva ?? this.afiliacionActiva,
      fechaUltimoExamen: fechaUltimoExamen ?? this.fechaUltimoExamen,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      estadoCita: estadoCita ?? this.estadoCita,
      fechaProximaCita: fechaProximaCita ?? this.fechaProximaCita,
      validacionCajacopi: validacionCajacopi ?? this.validacionCajacopi,
      tipoIdentificacion: tipoIdentificacion ?? this.tipoIdentificacion,
    );
  }
}

enum EstadoCita {
  preAgenda('Pre-agenda'),
  agenda('Agenda'),
  listo('Listo'),
  cancelado('Cancelado'),
  ninguno('Ninguno');

  const EstadoCita(this.nombre);
  final String nombre;
}
