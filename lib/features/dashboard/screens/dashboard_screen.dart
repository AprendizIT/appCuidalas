import 'package:flutter/material.dart';
import '../../auth/widgets/user_drawer.dart';
import '../../auth/models/usuario.dart';
import '../../../core/theme/app_theme.dart';
import '../../pacientes/screens/consulta_screen.dart';
import '../widgets/stats_card.dart';
import '../services/consultas_analytics_service.dart';

class DashboardScreen extends StatefulWidget {
  final bool openConsulta;
  const DashboardScreen({super.key, this.openConsulta = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey _consultaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    // Inicializar con datos de ejemplo para demostración
    ConsultasAnalyticsService().inicializarConDatosEjemplo();
    
    if (widget.openConsulta) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showConsultaIfNeeded());
    }
  }

  void _showConsultaIfNeeded() {
    final width = MediaQuery.of(context).size.width;
    // Si es pantalla pequeña, hacer scroll para que la consulta sea visible
    if (width <= 900) {
      final ctx = _consultaKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300), alignment: 0.1);
      }
    } else {
      // En pantallas anchas la consulta ya está visible en la columna izquierda
      // podríamos hacer otras interacciones si se requiere en el futuro
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    final consulta = const ConsultaWidget();
    final stats = const StatsCard();

    return Scaffold(
      drawer: const UserDrawer(usuario: usuarioDemo),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration:
                  const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.favorite, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            const Text('Cuídalas'),
          ],
        ),
        backgroundColor: AppColors.onPrimary, // antes: Color.fromRGBO(255,255,255,1)
        foregroundColor: AppColors.text,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: consulta),
                    const SizedBox(width: 10),
                    Expanded(child: stats),
                  ],
                );
              }

              return ListView(
                children: [
                  stats,
                  const SizedBox(height: 10),
                  // envolver en Key para poder hacer ensureVisible
                  Container(key: _consultaKey, child: consulta),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
