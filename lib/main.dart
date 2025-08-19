import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/ubicacion_screen.dart';
import 'features/pacientes/screens/validacion_screen.dart';
import 'features/citas/screens/agendamiento_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

void main() {
  runApp(const CuidalasApp());
}

class CuidalasApp extends StatelessWidget {
  const CuidalasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConsts.appName,
      theme: AppTheme.light,
      initialRoute: AppConsts.routeLogin,
      routes: {
        AppConsts.routeLogin: (_) => const LoginScreen(),
        AppConsts.routeUbicacion: (_) => const UbicacionScreen(),
        AppConsts.routeDashboard: (_) => const DashboardScreen(),
        AppConsts.routeValidacion: (_) => const ValidacionScreen(),
        AppConsts.routeAgendar: (_) => const AgendamientoScreen(),
      },
    );
  }
}
