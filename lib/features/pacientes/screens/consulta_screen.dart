import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../widgets/consulta_resultados.dart';
import '../models/paciente.dart';
import '../services/paciente_service.dart';
import '../services/cajacopi_service.dart';
import '../models/validacion_tamizaje.dart';

class ConsultaWidget extends StatefulWidget {
  const ConsultaWidget({super.key});

  @override
  State<ConsultaWidget> createState() => _ConsultaWidgetState();
}

class _ConsultaWidgetState extends State<ConsultaWidget> {
  final _idCtrl = TextEditingController();
  Paciente? _pacienteEncontrado;
  bool _consultando = false;
  String? _errorMessage;

  // Lista de tipos de documento soportados (code, label)
  final List<Map<String, String>> _documentTypes = const [
    {'code': 'CC', 'label': 'Cédula de ciudadanía'},
    {'code': 'TI', 'label': 'Tarjeta de identidad'},
    {'code': 'RC', 'label': 'Registro civil'},
    {'code': 'NIT', 'label': 'NIT'},
    {'code': 'PA', 'label': 'Pasaporte'},
    {'code': 'CE', 'label': 'Cédula extranjera'},
  ];

  String _selectedTipoDoc = 'CC';

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  bool _tipoDocumentoAceptaSoloNumeros(String tipo) {
    // Tipos que deben ser numéricos en nuestra lógica
    const numeric = {'CC', 'TI', 'RC', 'NIT', 'CE'};
    return numeric.contains(tipo.toUpperCase());
  }

  Future<void> _consultarPaciente() async {
    final raw = _idCtrl.text.trim();

    if (raw.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingrese una cédula');
      return;
    }

    // Validaciones basadas en tipo de documento seleccionado
    if (_tipoDocumentoAceptaSoloNumeros(_selectedTipoDoc)) {
      if (RegExp(r'\D').hasMatch(raw)) {
        setState(
            () => _errorMessage = 'Este tipo de documento acepta sólo números');
        return;
      }
      if (raw.length < 6) {
        setState(() => _errorMessage =
            'Número demasiado corto para este tipo de documento');
        return;
      }
    } else {
      // Para tipos que admiten letras (pasaporte, etc) validar longitud mínima
      if (raw.length < 4) {
        setState(() => _errorMessage =
            'Número demasiado corto para este tipo de documento');
        return;
      }
    }

    setState(() {
      _consultando = true;
      _errorMessage = null;
      _pacienteEncontrado = null;
    });

    try {
      // 1. Buscar paciente en Odoo
      var paciente = await PacienteService.buscarPorCedula(raw,
          tipoDocumento: _selectedTipoDoc);

      if (paciente != null) {
        // 2. Validar en CajaCopi
        setState(() {
          // Actualizar UI para mostrar que se está validando con CajaCopi
        });

        // Enviar a Cajacopi el valor almacenado en Odoo si está disponible,
        // en caso contrario usar el valor ingresado por el usuario (raw).
        final numeroParaCajacopi =
            (paciente.cedula.isNotEmpty) ? paciente.cedula : raw;

        final validacionCajacopi = await CajacopiService.consultarAfiliacion(
          tipoDocumento:
              CajacopiService.mapearTipoDocumento(paciente.tipoIdentificacion),
          numeroDocumento: numeroParaCajacopi,
        );

        // 3. Actualizar paciente con la validación de CajaCopi
        paciente = paciente.copyWith(
          validacionCajacopi: ValidacionCajacopi.fromJson(validacionCajacopi),
        );

        // Si CajaCopi indica que está activo, actualizar el estado de afiliación
        if (validacionCajacopi['activo'] == true) {
          paciente = paciente.copyWith(afiliacionActiva: true);
        }
      }

      setState(() {
        _consultando = false;
        if (paciente != null) {
          _pacienteEncontrado = paciente;
        } else {
          _errorMessage = 'Cédula no encontrada en el sistema';
        }
      });
    } catch (e) {
      setState(() {
        _consultando = false;
        _errorMessage = 'Error al consultar. Intente nuevamente.';
      });
      print('Error en consulta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Text('Tipo de documento',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            // Dropdown para seleccionar tipo de documento
            DropdownButton<String>(
              value: _selectedTipoDoc,
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
              underline: Container(height: 1, color: Colors.grey[300]),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTipoDoc = newValue!;
                  _errorMessage =
                      null; // Reiniciar mensaje de error al cambiar tipo
                  _pacienteEncontrado = null; // Reiniciar paciente encontrado
                  _idCtrl.clear(); // Limpiar campo de cédula
                });
              },
              items: _documentTypes
                  .map<DropdownMenuItem<String>>((Map<String, String> value) {
                return DropdownMenuItem<String>(
                  value: value['code'],
                  child: Text(value['label']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(_selectedTipoDoc == 'CC' ? 'Cédula' : 'Número de documento',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            // Mostrar campo de entrada o información de cédula consultada
            if (_pacienteEncontrado == null) ...[
              // Campo normal para escribir
              TextField(
                controller: _idCtrl,
                keyboardType: _tipoDocumentoAceptaSoloNumeros(_selectedTipoDoc)
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters:
                    _tipoDocumentoAceptaSoloNumeros(_selectedTipoDoc)
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                decoration: InputDecoration(
                  hintText: _tipoDocumentoAceptaSoloNumeros(_selectedTipoDoc)
                      ? 'Ingrese número (solo dígitos)'
                      : 'Ingrese número de documento',
                  errorText: _errorMessage,
                ),
                onSubmitted: (_) => _consultarPaciente(),
              ),
            ] else ...[
              // Información de cédula consultada (estilo elegante)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.credit_card,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cédula consultada',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _idCtrl.text,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Botón pequeño para nueva consulta (opcional)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _idCtrl.clear();
                          _pacienteEncontrado = null;
                          _errorMessage = null;
                        });
                      },
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'Cambiar cédula',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (_pacienteEncontrado == null && !_consultando)
              const ConsultaResultados(
                criterios: [
                  'Edad entre 25 a 49 años',
                  'Afiliada activa en Cajacopi EPS',
                  'Último examen hace 2 años o más',
                ],
              ),
            if (_pacienteEncontrado != null) ...[
              _buildPacienteInfo(_pacienteEncontrado!),
              const SizedBox(height: 16),
              _buildEstadoValidacion(_pacienteEncontrado!),
            ],
            // Solo mostrar botón si no se ha consultado aún
            if (_pacienteEncontrado == null && !_consultando) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _consultarPaciente,
                  icon: const Icon(Icons.search),
                  label: const Text('Verificar elegibilidad'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],

            // Mostrar loading cuando está consultando
            if (_consultando) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Verificando elegibilidad...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPacienteInfo(Paciente paciente) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppColors.primary, size: 20),
                const SizedBox(width: 30),
                Text('Información del paciente',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow('Nombre completo', paciente.nombreCompleto),
            _InfoRow('Edad', '${paciente.edad} años'),
            _InfoRow(
              'Estado de afiliación',
              paciente.afiliacionActiva ? 'Activo en Odoo' : 'Inactivo en Odoo',
              isStatus: true,
              isActive: paciente.afiliacionActiva,
            ),
            _InfoRow(
                'Último examen',
                paciente.fechaUltimoExamen != null
                    ? '${paciente.fechaUltimoExamen!.day}/${paciente.fechaUltimoExamen!.month}/${paciente.fechaUltimoExamen!.year}'
                    : 'Sin registro'),
            _InfoRow('Teléfono', paciente.telefono, isEditable: true),
            _InfoRow('Correo', paciente.email, isEditable: true),
          ],
        ),
      ),
    );
  }

  Widget _InfoRow(String label, String value,
      {bool isStatus = false, bool isActive = false, bool isEditable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isStatus) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: isActive ? AppColors.success : AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
                if (isEditable) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Funcionalidad de edición (próximamente)')),
                      );
                    },
                    child: const Icon(Icons.edit,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoValidacion(Paciente paciente) {
    final esApto = paciente.esAptoParaAgendar;
    final motivo = paciente.motivoNoApto;

    return Column(
      children: [
        if (esApto) ...[
          // Botón principal - Agendar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppConsts.routeAgendar),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Agendar cita'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ] else ...[
          // Mensaje de no elegibilidad
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No cumple requisitos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(motivo, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Botón "Nueva consulta" - aparece siempre después de cualquier consulta
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _idCtrl.clear();
                _pacienteEncontrado = null;
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Nueva consulta'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
