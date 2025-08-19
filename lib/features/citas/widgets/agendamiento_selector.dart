import 'package:flutter/material.dart';

class AgendamientoSelector extends StatelessWidget {
  final DateTime? fecha;
  final TimeOfDay? hora;
  final VoidCallback onPickFecha;
  final VoidCallback onPickHora;

  const AgendamientoSelector({
    super.key,
    required this.fecha,
    required this.hora,
    required this.onPickFecha,
    required this.onPickHora,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickFecha,
            icon: const Icon(Icons.date_range),
            label: Text(fecha != null
                ? '${fecha!.day}/${fecha!.month}/${fecha!.year}'
                : 'Elegir fecha'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickHora,
            icon: const Icon(Icons.schedule),
            label: Text(hora != null ? hora!.format(context) : 'Elegir hora'),
          ),
        ),
      ],
    );
  }
}
