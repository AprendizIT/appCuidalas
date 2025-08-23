import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../models/usuario.dart';

class UserDrawer extends StatelessWidget {
  final Usuario usuario;

  const UserDrawer({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header con info del usuario
          _buildUserHeader(context),

          const SizedBox(height: 8),

          // Sección de referidos
          _buildReferidosSection(context),

          const Divider(height: 24),

          // Opciones del menú
          _buildMenuTile(
            context,
            icon: Icons.person_add,
            title: 'Agregar referido',
            onTap: () => _mostrarDialogoReferido(context),
          ),

          _buildMenuTile(
            context,
            icon: Icons.help_outline,
            title: 'Instructivo de la app',
            onTap: () => _mostrarInstructivo(context),
          ),

          _buildMenuTile(
            context,
            icon: Icons.settings,
            title: 'Configuración',
            onTap: () => _mostrarConfiguracion(context),
          ),

          _buildMenuTile(
            context,
            icon: Icons.info_outline,
            title: 'Acerca de',
            onTap: () => _mostrarAcercaDe(context),
          ),

          const Divider(height: 24),

          // Botón cerrar sesión
          _buildMenuTile(
            context,
            icon: Icons.logout,
            title: 'Cerrar sesión',
            textColor: AppColors.danger,
            onTap: () => _cerrarSesion(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto de perfil
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage:
                  usuario.foto != null ? NetworkImage(usuario.foto!) : null,
              child: usuario.foto == null
                  ? Text(
                      usuario.nombre
                          .split(' ')
                          .map((n) => n[0])
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Nombre
          Text(
            usuario.nombre,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            usuario.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 2),

          // Ubicación
          Row(
            children: [
              Icon(Icons.location_on,
                  size: 14, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  usuario.ubicacion,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferidosSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Red de Referidos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Puntos totales
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${usuario.puntosReferidos} puntos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Desglose de referidos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReferidosStat(
                  'Principales', usuario.referidosPrincipales, AppColors.text),
              _buildReferidosStat(
                  'Secundarios', usuario.referidosSecundarios, AppColors.text),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferidosStat(String label, int cantidad, Color color) {
    return Column(
      children: [
        Text(
          cantidad.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _mostrarDialogoReferido(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Agregar Referido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                hintText: 'Nombre del referido',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                hintText: '+57 300 123 4567',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Referido agregado exitosamente'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _mostrarInstructivo(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Instructivo'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📱 Cómo usar Cuídalas:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. Ingresa la cédula de la paciente'),
              Text('2. Verifica que cumpla los criterios'),
              Text('3. Agenda la cita si es apta'),
              Text('4. Refiere nuevos usuarios para ganar puntos'),
              SizedBox(height: 12),
              Text('💰 Sistema de puntos:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Referido principal: 100 puntos'),
              Text('• Referido secundario: 50 puntos'),
              Text('• Los puntos se acumulan mensualmente'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _mostrarConfiguracion(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración (próximamente)')),
    );
  }

  void _mostrarAcercaDe(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.favorite, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Cuídalas'),
          ],
        ),
        content: const Text(
          'Cuídalas v2.0\n\nAplicación para la gestión de tamizajes y agendamiento de citas médicas.\n\nDesarrollado por Cure Latam.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConsts.routeLogin,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
