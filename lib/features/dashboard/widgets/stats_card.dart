import 'package:flutter/material.dart';
import 'pacientes_pie_chart_widget.dart';
import 'consultas_bar_chart_widget.dart';

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
                      _PacientesEfectivosSection(),
                      const SizedBox(height: 20),
                      _ConsultasRealizadasSection(),
                    ],
                  );
                }
                // Otherwise use horizontal layout
                return Column(
                  children: [
                    _PacientesEfectivosSection(),
                    const SizedBox(height: 24),
                    _ConsultasRealizadasSection(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PacientesEfectivosSection extends StatelessWidget {
  const _PacientesEfectivosSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Pacientes Efectivos vs Agendados',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const PacientesPieChartWidget(),
      ],
    );
  }
}

class _ConsultasRealizadasSection extends StatelessWidget {
  const _ConsultasRealizadasSection();

  @override
  Widget build(BuildContext context) {
    return const ConsultasBarChartWidget();
  }
}
