import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../services/consultas_analytics_service.dart';

class ConsultasChartWidget extends StatelessWidget {
  const ConsultasChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConsultasAnalyticsService(),
      builder: (context, child) {
        final analytics = ConsultasAnalyticsService();
        
        if (analytics.totalConsultas == 0) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            SizedBox(
              height: 165,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      color: AppColors.primary,
                      value: analytics.consultasAptas.toDouble(),
                      title: analytics.porcentajeAptos > 8 
                          ? '${analytics.porcentajeAptos.toStringAsFixed(0)}%' 
                          : '',
                      titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      radius: 50,
                    ),
                    PieChartSectionData(
                      color: AppColors.textSecondary,
                      value: analytics.consultasNoAptas.toDouble(),
                      title: analytics.porcentajeNoAptos > 8 
                          ? '${analytics.porcentajeNoAptos.toStringAsFixed(0)}%' 
                          : '',
                      titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(context, analytics),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total: ${analytics.totalConsultas}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend(BuildContext context, ConsultasAnalyticsService analytics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If space is too tight, stack vertically
        if (constraints.maxWidth < 120) {
          return Column(
            children: [
              _LegendItem(
                color: AppColors.primary,
                label: 'Aptos',
                value: analytics.consultasAptas,
                isCompact: true,
              ),
              const SizedBox(height: 4),
              _LegendItem(
                color: AppColors.textSecondary,
                label: 'No Aptos',
                value: analytics.consultasNoAptas,
                isCompact: true,
              ),
            ],
          );
        }
        // Otherwise use horizontal layout with flexible spacing
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            _LegendItem(
              color: AppColors.primary,
              label: 'Aptos',
              value: analytics.consultasAptas,
            ),
            _LegendItem(
              color: AppColors.textSecondary,
              label: 'No Aptos',
              value: analytics.consultasNoAptas,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 36,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin datos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Realiza consultas para ver estadísticas',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final bool isCompact;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCompact ? 6 : 8,
          height: isCompact ? 6 : 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isCompact ? 3 : 4),
        Flexible(
          child: Text(
            '$label ($value)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: isCompact ? 10 : 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
