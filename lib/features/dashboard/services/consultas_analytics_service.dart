import 'package:flutter/foundation.dart';

class ConsultasAnalyticsService extends ChangeNotifier {
  static final ConsultasAnalyticsService _instance = ConsultasAnalyticsService._internal();
  factory ConsultasAnalyticsService() => _instance;
  ConsultasAnalyticsService._internal();

  int _consultasAptas = 0;
  int _consultasNoAptas = 0;

  int get consultasAptas => _consultasAptas;
  int get consultasNoAptas => _consultasNoAptas;
  int get totalConsultas => _consultasAptas + _consultasNoAptas;

  double get porcentajeAptos {
    if (totalConsultas == 0) return 0.0;
    return (_consultasAptas / totalConsultas) * 100;
  }

  double get porcentajeNoAptos {
    if (totalConsultas == 0) return 0.0;
    return (_consultasNoAptas / totalConsultas) * 100;
  }

  void registrarConsultaApta() {
    _consultasAptas++;
    notifyListeners();
    if (kDebugMode) {
      print('📊 Consulta APTA registrada. Total aptas: $_consultasAptas');
    }
  }

  void registrarConsultaNoApta() {
    _consultasNoAptas++;
    notifyListeners();
    if (kDebugMode) {
      print('📊 Consulta NO APTA registrada. Total no aptas: $_consultasNoAptas');
    }
  }

  void reset() {
    _consultasAptas = 0;
    _consultasNoAptas = 0;
    notifyListeners();
    if (kDebugMode) {
      print('📊 Estadísticas de consultas reseteadas');
    }
  }

  // Método para inicializar con datos de ejemplo (para testing)
  void inicializarConDatosEjemplo() {
    _consultasAptas = 89; // Consultas que resultaron aptas
    _consultasNoAptas = 23; // Consultas que no fueron aptas
    notifyListeners();
    if (kDebugMode) {
      print('📊 Datos de ejemplo cargados: $_consultasAptas aptas, $_consultasNoAptas no aptas (${porcentajeAptos.toStringAsFixed(1)}% de éxito)');
    }
  }
}
