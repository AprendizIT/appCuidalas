import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../services/pacientes_analytics_service.dart';

class PacientesPieChartWidget extends StatefulWidget {
  const PacientesPieChartWidget({super.key});

  @override
  State<PacientesPieChartWidget> createState() => _PacientesPieChartWidgetState();
}

class _PacientesPieChartWidgetState extends State<PacientesPieChartWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  PacientesAnalyticsService? _analytics;
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios de ciclo de vida para re-animar al volver a la app
    WidgetsBinding.instance.addObserver(this);
    _analytics = PacientesAnalyticsService();
    _analytics?.addListener(_onAnalyticsUpdated);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Curved animation para suavizar la interpolación y evitar "saltos" al final
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    // Si ya hay datos, arrancar la animación después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((_analytics?.totalPacientes ?? 0) > 0) _runAnimation();
    });
  }

  void _onAnalyticsUpdated() {
    // Reiniciar animación cuando cambian los datos
    if (!mounted) return;
    if ((_analytics?.totalPacientes ?? 0) == 0) {
      _ctrl.value = 0.0;
      setState(() {});
      return;
    }
    _runAnimation();
  }

  void _runAnimation() {
    _ctrl
      ..stop()
      ..value = 0.0
      ..forward();
  }

  @override
  void dispose() {
    _analytics?.removeListener(_onAnalyticsUpdated);
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Al volver a la app, re-ejecutar la animación si hay datos
      if (mounted && (_analytics?.totalPacientes ?? 0) > 0) {
        _runAnimation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((_analytics?.totalPacientes ?? 0) == 0) return _buildEmptyState(context);

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final progress = _curve.value; // ya aplica easeOutCubic

        final targetEfectivos = (_analytics?.pacientesEfectivos ?? 0).toDouble();
        final targetAgendados = (_analytics?.pacientesAgendados ?? 0).toDouble();

        final animEfectivos = targetEfectivos * progress;
        final animAgendados = targetAgendados * progress;
        final animTotal = animEfectivos + animAgendados;

        final displayPctEfectivos = animTotal == 0 ? 0.0 : (animEfectivos / animTotal) * 100;
        final displayPctAgendados = animTotal == 0 ? 0.0 : (animAgendados / animTotal) * 100;

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
                      value: animEfectivos,
                      title: displayPctEfectivos > 8 ? '${displayPctEfectivos.toStringAsFixed(0)}%' : '',
                      titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      radius: 50,
                    ),
                    PieChartSectionData(
                      color: AppColors.textSecondary,
                      value: animAgendados,
                      title: displayPctAgendados > 8 ? '${displayPctAgendados.toStringAsFixed(0)}%' : '',
                      titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      radius: 50,
                    ),
                    // Filler section para animar el llenado del gráfico desde 0 hasta el total
                    PieChartSectionData(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
                      value: ( (targetEfectivos + targetAgendados) - (animEfectivos + animAgendados) ).clamp(0.0, (targetEfectivos + targetAgendados)),
                      title: '',
                      radius: 50,
                      showTitle: false,
                    ),
                  ],
                ),
                // Desactivar la animación interna del paquete para confiar
                // únicamente en nuestra AnimationController y evitar dobles interpolaciones
                swapAnimationDuration: Duration.zero,
                swapAnimationCurve: Curves.linear,
              ),
            ),
            const SizedBox(height: 16),
            if (_analytics != null) _buildLegend(context, _analytics!),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total: ${animTotal.round()}',
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

  Widget _buildLegend(BuildContext context, PacientesAnalyticsService analytics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If space is too tight, stack vertically
        if (constraints.maxWidth < 120) {
          return Column(
            children: [
              _LegendItem(
                color: AppColors.primary,
                label: 'Efectivos',
                value: analytics.pacientesEfectivos,
                isCompact: true,
              ),
              const SizedBox(height: 4),
              _LegendItem(
                color: AppColors.textSecondary,
                label: 'Agendados',
                value: analytics.pacientesAgendados,
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
              label: 'Efectivos',
              value: analytics.pacientesEfectivos,
            ),
            _LegendItem(
              color: AppColors.textSecondary,
              label: 'Agendados',
              value: analytics.pacientesAgendados,
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
                  Icons.people_outlined,
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
          'Agregue pacientes para ver estadísticas',
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
