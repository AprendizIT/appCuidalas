import 'package:flutter/material.dart';
import '../widgets/agendamiento_selector.dart';
import '../../pacientes/models/paciente.dart';
import '../../../core/theme/app_theme.dart';

class AgendamientoScreen extends StatefulWidget {
  final Paciente? paciente;

  const AgendamientoScreen({super.key, this.paciente});

  @override
  State<AgendamientoScreen> createState() => _AgendamientoScreenState();
}

class _AgendamientoScreenState extends State<AgendamientoScreen> {
  DateTime? fecha;
  TimeOfDay? hora;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar cita')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.paciente != null) ...[
            Card(
              color: AppColors.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Paciente',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(widget.paciente!.nombreCompleto,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('Cédula: ${widget.paciente!.cedula}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selecciona fecha y hora',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  AgendamientoSelector(
                    fecha: fecha,
                    hora: hora,
                    onPickFecha: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 120)),
                        initialDate: fecha ?? now,
                      );
                      if (picked != null) setState(() => fecha = picked);
                    },
                    onPickHora: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: hora ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => hora = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (fecha != null && hora != null)
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(widget.paciente != null
                                      ? 'Cita confirmada para ${widget.paciente!.nombreCompleto}'
                                      : 'Cita confirmada (demo)'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          : null,
                      child: const Text('Confirmar cita'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
