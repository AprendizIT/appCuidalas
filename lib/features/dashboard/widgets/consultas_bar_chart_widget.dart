import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/consultas_analytics_service.dart';

class ConsultasBarChartWidget extends StatefulWidget {
  const ConsultasBarChartWidget({super.key});

  @override
  State<ConsultasBarChartWidget> createState() => _ConsultasBarChartWidgetState();
}

class _ConsultasBarChartWidgetState extends State<ConsultasBarChartWidget> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ConsultasAnalyticsService? _analytics;
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _analytics = ConsultasAnalyticsService();
    _analytics?.addListener(_onAnalyticsUpdated);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    // Iniciar animación después del primer frame si hay datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((_analytics?.totalConsultas ?? 0) > 0) _runAnimation();
    });
  }

  void _runAnimation() {
    _ctrl
      ..stop()
      ..value = 0.0
      ..forward();
  }

  void _onAnalyticsUpdated() {
    if (!mounted) return;
    if ((_analytics?.totalConsultas ?? 0) == 0) {
      _ctrl.value = 0.0;
      setState(() {});
      return;
    }
    _runAnimation();
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
      if (mounted && (_analytics?.totalConsultas ?? 0) > 0) {
        _runAnimation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((_analytics?.totalConsultas ?? 0) == 0) {
      return _buildEmptyState(context);
    }

    final consultasData = [
      ConsultasBarData(
        label: 'Pacientes Aptos',
        icon: Icons.check_circle_outline,
        color: AppColors.primary,
        value: _analytics!.consultasAptas.toDouble(),
      ),
      ConsultasBarData(
        label: 'Pacientes No Aptos',
        icon: Icons.cancel_outlined,
        color: AppColors.textSecondary,
        value: _analytics!.consultasNoAptas.toDouble(),
      ),
    ];

    final maxValue = consultasData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final progress = _curve.value;

        // Crear lista animada donde los valores se escalan por el progreso
        final animatedData = consultasData
            .map((d) => ConsultasBarData(
                  label: d.label,
                  icon: d.icon,
                  color: d.color,
                  value: d.value * progress,
                ))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Consultas Realizadas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 16),

            // Barras horizontales personalizadas (animadas)
            Column(
              children: animatedData
                  .map((data) => _buildHorizontalBar(context, data, maxValue))
                  .toList(),
            ),

            // Leyenda con valores totales (animados)
            const SizedBox(height: 12),
            _buildLegend(context, animatedData),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalBar(BuildContext context, ConsultasBarData data, double maxValue) {
    final percentage = maxValue > 0 ? data.value / maxValue : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Ícono
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Barra horizontal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${data.value.toInt()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: data.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: data.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, List<ConsultasBarData> data) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${item.label}: ${item.value.toInt()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Text(
          'Consultas Realizadas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'Realiza consultas para ver estadísticas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ConsultasBarData {
  const ConsultasBarData({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double value;
}
