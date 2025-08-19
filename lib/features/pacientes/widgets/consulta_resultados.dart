import 'package:flutter/material.dart';

class ConsultaResultados extends StatelessWidget {
  final List<String> criterios;
  const ConsultaResultados({super.key, required this.criterios});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...criterios.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child:
                        Icon(Icons.circle, size: 8, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(c,
                          style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            )),
      ],
    );
  }
}
