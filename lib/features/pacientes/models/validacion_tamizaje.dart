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
    return ValidacionCajacopi(
      existe: json['existe'] ?? false,
      estado: json['estado'] ?? 'DESCONOCIDO',
      regimen: json['regimen'],
      activo: json['activo'] ?? false,
      mensaje: json['mensaje'] ?? '',
      datosCompletos: json['datos'],
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
