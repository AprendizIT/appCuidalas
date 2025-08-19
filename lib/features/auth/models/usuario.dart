class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final String ubicacion;
  final String? foto;
  final int puntosReferidos;
  final int referidosPrincipales;
  final int referidosSecundarios;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.ubicacion,
    this.foto,
    this.puntosReferidos = 0,
    this.referidosPrincipales = 0,
    this.referidosSecundarios = 0,
  });
}

// Usuario simulado para demo
const usuarioDemo = Usuario(
  id: '12345',
  nombre: 'María Fernanda López',
  email: 'maria.lopez@cajacopi.com',
  telefono: '+57 300 123 4567',
  ubicacion: 'Bogotá, Cundinamarca',
  puntosReferidos: 850,
  referidosPrincipales: 12,
  referidosSecundarios: 8,
);
