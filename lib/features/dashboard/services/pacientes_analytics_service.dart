import 'package:flutter/foundation.dart';

class PacientesAnalyticsService extends ChangeNotifier {
  static final PacientesAnalyticsService _instance = PacientesAnalyticsService._internal();
  factory PacientesAnalyticsService() => _instance;
  PacientesAnalyticsService._internal();

  int _pacientesEfectivos = 0;
  int _pacientesAgendados = 0;

  int get pacientesEfectivos => _pacientesEfectivos;
  int get pacientesAgendados => _pacientesAgendados;
  int get totalPacientes => _pacientesEfectivos + _pacientesAgendados;

  double get porcentajeEfectivos {
    if (totalPacientes == 0) return 0.0;
    return (_pacientesEfectivos / totalPacientes) * 100;
  }

  double get porcentajeAgendados {
    if (totalPacientes == 0) return 0.0;
    return (_pacientesAgendados / totalPacientes) * 100;
  }

  void registrarPacienteEfectivo() {
    _pacientesEfectivos++;
    notifyListeners();
    if (kDebugMode) {
      print('📊 Paciente EFECTIVO registrado. Total efectivos: $_pacientesEfectivos');
    }
  }

  void registrarPacienteAgendado() {
    _pacientesAgendados++;
    notifyListeners();
    if (kDebugMode) {
      print('📊 Paciente AGENDADO registrado. Total agendados: $_pacientesAgendados');
    }
  }

  void reset() {
    _pacientesEfectivos = 0;
    _pacientesAgendados = 0;
    notifyListeners();
    if (kDebugMode) {
      print('📊 Estadísticas de pacientes reseteadas');
    }
  }

  // Método para inicializar con datos de ejemplo (para testing)
  void inicializarConDatosEjemplo() {
    _pacientesEfectivos = 127; // Pacientes que asistieron efectivamente
    _pacientesAgendados = 185; // Total de pacientes agendados para el día
    notifyListeners();
    if (kDebugMode) {
      print('📊 Datos de ejemplo cargados: $_pacientesEfectivos efectivos, $_pacientesAgendados agendados (${porcentajeEfectivos.toStringAsFixed(1)}% efectividad)');
    }
  }
}
