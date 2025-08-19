import '../models/paciente.dart';
import 'paciente_odoo_service.dart';

class PacienteService {
  // Modo de operación: true = usar Odoo, false = usar datos mock
  static bool _useOdoo = true;

  /// Cambia entre modo Odoo y modo mock
  static void setMockMode(bool useMock) {
    _useOdoo = !useMock;
  }

  static Future<Paciente?> buscarPorCedula(String cedula,
      {String tipoDocumento = 'CC'}) async {
    if (_useOdoo) {
      try {
        return await PacienteOdooService.buscarPorCedula(cedula,
            tipoDocumento: tipoDocumento);
      } catch (e) {
        print('Error consultando Odoo: $e');
        print('Fallback a datos mock...');
        return await _buscarPorCedulaMock(cedula);
      }
    } else {
      return await _buscarPorCedulaMock(cedula);
    }
  }

  // Datos de prueba
  static final Map<String, Paciente> _pacientes = {
    '1234567890': Paciente(
      cedula: '1234567890',
      nombreCompleto: 'María García López',
      edad: 32,
      afiliacionActiva: true,
      fechaUltimoExamen: DateTime(2021, 6, 15), // Hace más de 2 años
      telefono: '3001234567',
      email: 'maria.garcia@email.com',
      tipoIdentificacion: 'CC', // AGREGAR
    ),
    '0987654321': Paciente(
      cedula: '0987654321',
      nombreCompleto: 'Ana Rodríguez Silva',
      edad: 28,
      afiliacionActiva: false,
      fechaUltimoExamen: DateTime(2023, 12, 10), // Hace menos de 2 años
      telefono: '3009876543',
      email: 'ana.rodriguez@email.com',
      tipoIdentificacion: 'CC', // AGREGAR
    ),
    '1122334455': Paciente(
      cedula: '1122334455',
      nombreCompleto: 'Carmen Pérez Martín',
      edad: 55,
      afiliacionActiva: true,
      fechaUltimoExamen: null,
      telefono: '3001122334',
      email: 'carmen.perez@email.com',
      tipoIdentificacion: 'CC', // AGREGAR
    ),
    '5566778899': Paciente(
      cedula: '5566778899',
      nombreCompleto: 'Laura Sánchez Torres',
      edad: 35,
      afiliacionActiva: true,
      fechaUltimoExamen: DateTime(2022, 3, 20),
      telefono: '3005566778',
      email: 'laura.sanchez@email.com',
      estadoCita: EstadoCita.agenda,
      tipoIdentificacion: 'TI', // AGREGAR - Ejemplo con Tarjeta de Identidad
    ),
  };

  static Future<Paciente?> _buscarPorCedulaMock(String cedula) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 800));

    final cedulaLimpia = cedula.replaceAll(RegExp(r'[^0-9]'), '');
    return _pacientes[cedulaLimpia];
  }

  static List<String> get cedulasValidas => _pacientes.keys.toList();
}
