import 'package:flutter/material.dart';

class ValidacionScreen extends StatelessWidget {
  const ValidacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validación')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resultado de validación',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  const Text('La paciente cumple criterios para tamizaje.'),
                ],
              ),
            ),
          )
        ],

      ),
    );
  }
}
