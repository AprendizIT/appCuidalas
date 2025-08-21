import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'consultas_chart_widget.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha((0.12 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Estadísticas del día',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                // If width is too small, stack vertically
                if (constraints.maxWidth < 400) {
                  return Column(
                    children: [
                      _ConsultasRealizadasSection(),
                      const SizedBox(height: 20),
                      _buildStatsRow(context),
                    ],
                  );
                }
                // Otherwise use horizontal layout
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _ConsultasRealizadasSection(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildStatsRow(context),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.person_outline,
            iconColor: AppColors.primary,
            title: 'Pacientes\nEfectivos',
            value: '1.2M',
            context: context,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 80,
          width: 1,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withAlpha((0.15 * 255).round()),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatItem(
            icon: Icons.groups_outlined,
            iconColor: AppColors.primary,
            title: 'Pacientes\nAgendados',
            value: '48',
            context: context,
          ),
        ),
      ],
    );
  }
}

class _ConsultasRealizadasSection extends StatelessWidget {
  const _ConsultasRealizadasSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Consultas realizadas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const ConsultasChartWidget(),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final BuildContext context;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.3,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}
