import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/search_provider.dart';
import '../providers/reservation_provider.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  ConsumerState<BookingRequestScreen> createState() =>
      _BookingRequestScreenState();
}

class _BookingRequestScreenState
    extends ConsumerState<BookingRequestScreen> {
  final _msgCtrl = TextEditingController();
  DateTime? _fecha;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _loading = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) {
    const months = [
      'Ene','Feb','Mar','Abr','May','Jun',
      'Jul','Ago','Sep','Oct','Nov','Dic'
    ];
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _fecha = d);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart
          ? const TimeOfDay(hour: 9, minute: 0)
          : const TimeOfDay(hour: 18, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() {
        if (isStart) {
          _horaInicio = t;
        } else {
          _horaFin = t;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_fecha == null || _horaInicio == null || _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona fecha y horario'),
            backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_msgCtrl.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('El mensaje debe tener al menos 20 caracteres'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    final user = ref.read(authProvider).valueOrNull;
    if (user != null && !user.isVerified) {
      _showKycRequiredDialog(user.isPending, user.isRejected);
      return;
    }

    final garage = ref.read(selectedGarageProvider);
    if (garage == null) return;

    final selectedServices = ref.read(selectedServicesProvider);

    setState(() => _loading = true);
    try {
      final reservation =
          await ref.read(reservationProvider.notifier).createReservation(
                garageId: garage.id,
                fecha: _formatDate(_fecha!),
                horaInicio: _formatTime(_horaInicio!),
                horaFin: _formatTime(_horaFin!),
                mensaje: _msgCtrl.text.trim(),
                serviciosIds:
                    selectedServices.map((s) => s.id).toList(),
              );
      if (mounted) {
        context.pushReplacement(
            AppRoutes.chat.replaceAll(':reservationId', reservation.id));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showKycRequiredDialog(bool isPending, bool isRejected) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isRejected ? Icons.gpp_bad_rounded : Icons.verified_user_outlined,
              color: isRejected ? AppTheme.error : AppTheme.primary,
            ),
            const SizedBox(width: 10),
            Text(
              isRejected ? 'Verificación Rechazada' : (isPending ? 'Verificación en curso' : 'Verificación requerida'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          isRejected
              ? 'Tu verificación previa fue rechazada. Por favor, revisa el motivo en tu perfil y vuelve a subir tus documentos.'
              : (isPending
                  ? 'Estamos revisando tus documentos. Podrás reservar en cuanto el administrador los apruebe.'
                  : 'Para poder reservar un espacio, primero debemos verificar tu identidad. Esto ayuda a mantener la comunidad segura.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cerrar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          if (!isPending)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.kyc);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isRejected ? 'Ver motivo' : 'Verificar ahora'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final garage = ref.watch(selectedGarageProvider);
    final msgLength = _msgCtrl.text.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text('Solicitar Reserva',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Garage summary
                    if (garage != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resumen de reserva',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: garage.primeraImagen.isNotEmpty
                                        ? Image.network(
                                            garage.primeraImagen,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                    color:
                                                        AppTheme.primaryLight),
                                          )
                                        : Container(
                                            color: AppTheme.primaryLight,
                                            child: const Icon(
                                                Icons.garage_outlined,
                                                color: AppTheme.primary)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(garage.nombre,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14),
                                          maxLines: 2),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.location_on_outlined,
                                              size: 12,
                                              color: AppTheme.textSecondary),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(garage.direccion,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme
                                                        .textSecondary),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '\$${garage.precioPorHora.toStringAsFixed(0)}/h',
                                          style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 20, color: AppTheme.border),

                            // Date & Time selectors
                            GestureDetector(
                              onTap: _pickDate,
                              child: _InfoRow(
                                icon: Icons.calendar_today_outlined,
                                label: _fecha != null
                                    ? _displayDate(_fecha!)
                                    : 'Seleccionar Fecha',
                                isSet: _fecha != null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickTime(true),
                                    child: _InfoRow(
                                      icon: Icons.schedule_outlined,
                                      label: _horaInicio != null
                                          ? _formatTime(_horaInicio!)
                                          : 'Hora Inicio',
                                      isSet: _horaInicio != null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickTime(false),
                                    child: _InfoRow(
                                      icon: Icons.schedule_outlined,
                                      label: _horaFin != null
                                          ? _formatTime(_horaFin!)
                                          : 'Hora Fin',
                                      isSet: _horaFin != null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Message to owner
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mensaje al propietario',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Obligatorio',
                              style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuéntale al propietario qué planeas vender. Una buena presentación aumenta tus posibilidades de aceptación.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        TextFormField(
                          controller: _msgCtrl,
                          maxLines: 6,
                          maxLength: 500,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'Hola, soy diseñadora de indumentaria y me gustaría usar el espacio para vender mi colección...',
                            hintStyle: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppTheme.border),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('$msgLength / 500',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Escribe al menos 20 caracteres para dar confianza al anfitrión.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Footer
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text('No se te cobrará nada todavía',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text('Enviar Solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSet;
  const _InfoRow(
      {required this.icon, required this.label, this.isSet = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSet ? AppTheme.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSet
                  ? AppTheme.primary.withOpacity(0.4)
                  : AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isSet ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSet ? FontWeight.w600 : FontWeight.w400,
                      color: isSet
                          ? AppTheme.primary
                          : AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}
