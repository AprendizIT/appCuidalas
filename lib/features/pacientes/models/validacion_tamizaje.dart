/// Modelo para el resultado de validación con CajaCopi
class ValidacionCajacopi {
  final bool existe;
  final String estado;
  final String? regimen;
  final bool activo;
  final String mensaje;
  final Map<String, dynamic>? datosCompletos;

  ValidacionCajacopi({
    required this.existe,
    required this.estado,
    this.regimen,
    required this.activo,
    required this.mensaje,
    this.datosCompletos,
  });

  factory ValidacionCajacopi.fromJson(Map<String, dynamic> json) {
    final rawEstado = (json['estado'] ?? 'DESCONOCIDO').toString();
    final estadoNormalizado = rawEstado.toUpperCase().trim();

    final activo = (json['activo'] ?? false) || (estadoNormalizado == 'ACTIVO');

    final mensajeFromJson = json['mensaje']?.toString();
    final mensaje = mensajeFromJson != null && mensajeFromJson.isNotEmpty
        ? mensajeFromJson
        : _mensajeDesdeEstado(estadoNormalizado);

    return ValidacionCajacopi(
      existe: json['existe'] ?? false,
      estado: estadoNormalizado,
      regimen: json['regimen']?.toString(),
      activo: activo,
      mensaje: mensaje,
      datosCompletos: json['datos'] as Map<String, dynamic>?,
    );
  }

  /// Crea una validación de error
  factory ValidacionCajacopi.error(String mensaje) {
    return ValidacionCajacopi(
      existe: false,
      estado: 'ERROR',
      activo: false,
      mensaje: mensaje,
    );
  }

  /// Crea una validación cuando no existe el afiliado
  factory ValidacionCajacopi.noExiste() {
    return ValidacionCajacopi(
      existe: false,
      estado: 'NO EXISTE',
      activo: false,
      mensaje: 'El usuario no existe en la base de datos de Cajacopi EPS',
    );
  }

  bool get esValido => existe && activo;

  static String _mensajeDesdeEstado(String estado) {
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
}

/// Resultado completo de validación de tamizaje
class ResultadoTamizaje {
  final bool esApto;
  final List<String> criteriosNoCumplidos;
  final ValidacionCajacopi? validacionCajacopi;
  final String mensajePrincipal;

  ResultadoTamizaje({
    required this.esApto,
    required this.criteriosNoCumplidos,
    this.validacionCajacopi,
    required this.mensajePrincipal,
  });
}
