import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';

class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  String? _departamentoSeleccionado;
  String? _municipioSeleccionado;
  String? _corregimiento;
  final _corregimientoCtrl = TextEditingController();

  // Datos simulados de ubicaciones
  final Map<String, List<String>> _ubicaciones = {
    'Cundinamarca': ['Bogotá', 'Soacha', 'Chía', 'Zipaquirá', 'Facatativá'],
    'Antioquia': ['Medellín', 'Bello', 'Itagüí', 'Envigado', 'Rionegro'],
    'Valle del Cauca': ['Cali', 'Palmira', 'Buenaventura', 'Tuluá', 'Cartago'],
    'Atlántico': ['Barranquilla', 'Soledad', 'Malambo', 'Puerto Colombia'],
    'Bolívar': ['Cartagena', 'Magangué', 'Turbaco', 'Arjona'],
  };

  @override
  void dispose() {
    _corregimientoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 700;

    Widget card = Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConsts.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(Icons.location_on,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text('Cuídalas',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 18),
            Text('Selecciona tu ubicación',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 6),
            Text('Indica desde dónde realizarás las consultas',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),

            // Selector de Departamento
            Text('Departamento',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _departamentoSeleccionado,
                  hint: Text('Selecciona departamento',
                      style: TextStyle(color: AppColors.textSecondary)),
                  isExpanded: true,
                  items: _ubicaciones.keys.map((String departamento) {
                    return DropdownMenuItem<String>(
                      value: departamento,
                      child: Text(departamento),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _departamentoSeleccionado = value;
                      _municipioSeleccionado = null; // Reset municipio
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selector de Municipio
            Text('Municipio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _departamentoSeleccionado == null
                    ? AppColors.bg
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _municipioSeleccionado,
                  hint: Text(
                      _departamentoSeleccionado == null
                          ? 'Primero selecciona departamento'
                          : 'Selecciona municipio',
                      style: TextStyle(color: AppColors.textSecondary)),
                  isExpanded: true,
                  items: _departamentoSeleccionado != null
                      ? _ubicaciones[_departamentoSeleccionado]!
                          .map((String municipio) {
                          return DropdownMenuItem<String>(
                            value: municipio,
                            child: Text(municipio),
                          );
                        }).toList()
                      : [],
                  onChanged: _departamentoSeleccionado != null
                      ? (String? value) {
                          setState(() {
                            _municipioSeleccionado = value;
                          });
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo de corregimiento (opcional)
            Text('Corregimiento (opcional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _corregimientoCtrl,
              decoration: InputDecoration(
                hintText: 'Ej: Corregimiento La Victoria',
                enabled: _municipioSeleccionado != null,
                filled: true,
                fillColor: _municipioSeleccionado == null
                    ? AppColors.bg
                    : Colors.white,
              ),
              onChanged: (value) => _corregimiento = value,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_departamentoSeleccionado != null &&
                        _municipioSeleccionado != null)
                    ? () {
                        FocusScope.of(context).unfocus();
                        // Mostrar confirmación
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ubicación guardada')),
                        );
                        // Navegar al dashboard (la consulta ahora está dentro del Dashboard)
                        Navigator.pushReplacementNamed(
                            context, AppConsts.routeDashboard);
                      }
                    : null,
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 420 : 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: card,
          ),
        ),
      ),
    );
  }
}
