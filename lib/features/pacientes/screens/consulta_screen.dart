import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../widgets/consulta_resultados.dart';
import '../models/paciente.dart';
import '../services/paciente_odoo_service.dart';
import '../services/cajacopi_service.dart';
import '../models/validacion_tamizaje.dart';
import '../../dashboard/services/consultas_analytics_service.dart';

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

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _consultarPaciente() async {
    final numeroDocumento = _idCtrl.text.trim();

    if (numeroDocumento.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingrese un número de documento');
      return;
    }

    if (numeroDocumento.length < 4) {
      setState(() => _errorMessage = 'Número de documento demasiado corto');
      return;
    }

    setState(() {
      _consultando = true;
      _errorMessage = null;
      _pacienteEncontrado = null;
    });

    try {
      // 1. Buscar paciente en Odoo (sin especificar tipo, lo detecta desde Odoo)
      var paciente = await PacienteOdooService.buscarPorDocumento(numeroDocumento);

      if (paciente != null) {
        // 2. Validar en CajaCopi usando el tipo de documento del paciente encontrado
        setState(() {
          // Actualizar UI para mostrar que se está validando con CajaCopi
        });

        print('🔄 Validando en CajaCopi con tipo: ${paciente.tipoIdentificacionDescripcion.isNotEmpty ? paciente.tipoIdentificacionDescripcion : paciente.tipoIdentificacion}');

        // La nueva firma devuelve ValidacionCajacopi directamente
        final ValidacionCajacopi validacionCajacopi = await CajacopiService.consultarAfiliacion(
          tipoDocumento: paciente.tipoIdentificacionDescripcion.isNotEmpty
              ? paciente.tipoIdentificacionDescripcion
              : paciente.tipoIdentificacion,
          numeroDocumento: paciente.cedula.isNotEmpty ? paciente.cedula : numeroDocumento,
        );

        // 3. Actualizar paciente con la validación de CajaCopi (modelo ya construido)
        paciente = paciente.copyWith(
          validacionCajacopi: validacionCajacopi,
        );

        // Si CajaCopi indica que está activo, actualizar el estado de afiliación
        if (validacionCajacopi.activo) {
          paciente = paciente.copyWith(afiliacionActiva: true);
        }
      }

      setState(() {
        _consultando = false;
        // No asignamos _pacienteEncontrado aquí para que la UI principal no cambie;
        // los resultados se mostrarán únicamente en el diálogo.
        if (paciente == null) {
          _errorMessage = 'Documento no encontrado en el sistema';
        } else {
          // 📊 Registrar consulta en analytics sin mutar la UI principal
          final analytics = ConsultasAnalyticsService();
          if (paciente.esAptoParaAgendar) {
            analytics.registrarConsultaApta();
          } else {
            analytics.registrarConsultaNoApta();
          }
        }
      });

      // Si se encontró paciente, mostrar los resultados en un diálogo modal
      if (paciente != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showResultadosPopup(paciente!);
        });
      }
    } catch (e) {
      setState(() {
        _consultando = false;
        _errorMessage = 'Error al consultar. Intente nuevamente.';
      });
      print('Error en consulta: $e');
    }
  }

  // Muestra un diálogo con la información y controles de la consulta
  void _showResultadosPopup(Paciente paciente) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.person, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Información del paciente',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.primary)),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _idCtrl.clear();
                            _pacienteEncontrado = null;
                            _errorMessage = null;
                          });
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPacienteInfo(paciente),
                  const SizedBox(height: 12),
                  _buildEstadoValidacion(paciente, cerrarDialogo: true),
                ],
              ),
            ),
          ),
        );
      },
    );
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
            // Campo único: Número de identificación
            if (_pacienteEncontrado == null) ...[
              // Input antes de la consulta
              Text(
                'Número de identificación',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _idCtrl,
                keyboardType: TextInputType.text, // Permitir letras y números
                decoration: InputDecoration(
                  hintText: 'Ingrese número de documento',
                  errorText: _errorMessage,
                ),
                onSubmitted: (_) => _consultarPaciente(),
              ),
            ] else ...[
              // Después de la consulta, mostrar el campo en modo solo lectura
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                            'Número de identificación',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _pacienteEncontrado!.cedula,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Mostrar tipo de documento (sigla) con tooltip que muestra la misma sigla
                              if (_pacienteEncontrado!.tipoIdentificacionDescripcion.isNotEmpty)
                                Tooltip(
                                  message: _pacienteEncontrado!.nombreTipoDocumento,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      _pacienteEncontrado!.tipoDocumentoCorto.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Botón para editar el número
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _idCtrl.text = _pacienteEncontrado!.cedula;
                          _pacienteEncontrado = null;
                          _errorMessage = null;
                        });
                      },
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'Editar número',
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
                  'Afiliación activa en Cajacopi EPS',
                  'Último examen hace más de 1 año (O nunca lo ha tenido)',
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
            _InfoRow('Nombre completo', paciente.nombreCompleto),
            _InfoRow('Tipo documento', paciente.nombreTipoDocumento),
            _InfoRow('Edad', '${paciente.edad} años'),
            if (paciente.validacionCajacopi != null) ...[
              _InfoRow(
                'Estado en Cajacopi',
                paciente.validacionCajacopi!.estado,
                isStatus: true,
                isActive: paciente.validacionCajacopi!.activo,
              ),
              if (paciente.validacionCajacopi!.regimen != null &&
                  paciente.validacionCajacopi!.regimen!.isNotEmpty)
                _InfoRow('Régimen', paciente.validacionCajacopi!.regimen!),
            ] else ...[
              _InfoRow(
                'Estado de afiliación',
                paciente.afiliacionActiva ? 'Activo en Odoo' : 'Inactivo en Odoo',
                isStatus: true,
                isActive: paciente.afiliacionActiva,
              ),
            ],
            _InfoRow(
                'Último examen',
                paciente.fechaUltimoExamen != null
                    ? '${paciente.fechaUltimoExamen!.day}/${paciente.fechaUltimoExamen!.month}/${paciente.fechaUltimoExamen!.year}'
                    : 'Sin registro'),
            if (paciente.telefono.isNotEmpty)
              _InfoRow('Teléfono', paciente.telefono, isEditable: true),
            if (paciente.email.isNotEmpty)
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
            width: 130,
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
                      maxLines: 2,
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

  Widget _buildEstadoValidacion(Paciente paciente, {bool cerrarDialogo = false}) {
    final esApto = paciente.esAptoParaAgendar;
    final motivo = paciente.motivoNoApto;

    return Column(
      children: [
        if (esApto) ...[
          // Botón principal - Agendar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppConsts.routeAgendar),
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
              // Cerrar diálogo si viene desde el modal
              if (cerrarDialogo) Navigator.of(context).pop();

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