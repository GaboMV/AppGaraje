import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/global_socket_provider.dart';
import '../providers/payment_upload_provider.dart';
import '../providers/sandbox_payment_provider.dart';

/// Pantalla de pago de reserva con dos modos:
///   â€¢ Tab 0 â€” Flujo real:   el usuario sube el comprobante manualmente.
///   â€¢ Tab 1 â€” Sandbox QR:   muestra el QR generado por el backend y permite
///             simular la confirmaciÃ³n del banco con un botÃ³n.
class PaymentUploadScreen extends ConsumerStatefulWidget {
  final String reservaId;
  const PaymentUploadScreen({super.key, required this.reservaId});

  @override
  ConsumerState<PaymentUploadScreen> createState() =>
      _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends ConsumerState<PaymentUploadScreen>
    with SingleTickerProviderStateMixin {
  // â”€â”€ Tabs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late final TabController _tabController;

  // â”€â”€ Upload manual â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  File? _voucherFile;
  final _picker = ImagePicker();
  static const int    _kImageQuality = 50;
  static const double _kMaxDimension = 1200;

  // â”€â”€ Socket cleanup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  VoidCallback? _offPagoExitoso;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Carga el QR sandbox en cuanto abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(sandboxPaymentProvider.notifier)
          .generateQr(widget.reservaId);

      // â”€â”€ SubscripciÃ³n al evento pago_exitoso â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Usamos el helper on() que devuelve un VoidCallback de limpieza.
      // Cuando el backend emite pago_exitoso (vÃ­a Socket.IO), mostramos
      // un SnackBar verde y hacemos pop automÃ¡tico a la pantalla anterior.
      _offPagoExitoso = ref.read(globalSocketProvider).on(
        'pago_exitoso',
        (data) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Â¡Pago Completado Exitosamente!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.secondary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          // PequeÃ±o delay para que el usuario vea el SnackBar antes del pop
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) context.pop();
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _offPagoExitoso?.call(); // Limpia el listener del socket
    _tabController.dispose();
    super.dispose();
  }

  // â”€â”€ Image picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source:       source,
      imageQuality: _kImageQuality,
      maxWidth:     _kMaxDimension,
      maxHeight:    _kMaxDimension,
    );
    if (picked != null) {
      final fileLength = await picked.length();
      if (fileLength > (2 * 1024 * 1024)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen es demasiado pesada incluso después de comprimir. Por favor, toma la foto desde más lejos o recórtala.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      setState(() => _voucherFile = File(picked.path));
      ref.read(paymentUploadProvider.notifier).reset();
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context:         context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            mainAxisSize:      MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color:        AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Seleccionar comprobante',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize:   16,
                  color:      AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _SourceTile(
                icon:  Icons.camera_alt_rounded,
                label: 'Tomar foto ahora',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _SourceTile(
                icon:  Icons.photo_library_rounded,
                label: 'Elegir de la galerÃ­a',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ Submit (flujo real) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _submit() async {
    if (_voucherFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Por favor selecciona una foto del comprobante.'),
          backgroundColor: AppTheme.error,
          behavior:        SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(paymentUploadProvider.notifier).submitVoucher(
          reservaId:   widget.reservaId,
          voucherFile: _voucherFile!,
        );

    if (!mounted) return;
    final uploadState = ref.read(paymentUploadProvider);
    if (uploadState.isSuccess) {
      _showSuccessAndPop();
    } else if (uploadState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(uploadState.errorMessage!),
          backgroundColor: AppTheme.error,
          behavior:        SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessAndPop() {
    showDialog<void>(
      context:            context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppTheme.secondary, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Â¡Pago enviado!',
                style: TextStyle(
                  fontSize:   20,
                  fontWeight: FontWeight.w800,
                  color:      AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu comprobante fue recibido. Tu reserva ya estÃ¡ marcada como PAGADA.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color:    AppTheme.textSecondary,
                  height:   1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('Volver a mis reservas'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(paymentUploadProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: uploadState.isLoading ? null : () => context.pop(),
        ),
        title: const Text('Pagar Reserva'),
        bottom: TabBar(
          controller: _tabController,
          labelColor:   AppTheme.primary,
          indicatorColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file_rounded),   text: 'Comprobante'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'QR Sandbox'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // â”€â”€ Tab 0: Flujo real â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _UploadTab(
            voucherFile:          _voucherFile,
            isLoading:            uploadState.isLoading,
            onPickTap:            _showImageSourceSheet,
            onSubmit:             _submit,
          ),

          // â”€â”€ Tab 1: QR Sandbox â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SandboxQrTab(reservaId: widget.reservaId),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Tab 0: Subida Manual â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _UploadTab extends StatelessWidget {
  final File?        voucherFile;
  final bool         isLoading;
  final VoidCallback onPickTap;
  final VoidCallback onSubmit;

  const _UploadTab({
    required this.voucherFile,
    required this.isLoading,
    required this.onPickTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [AppTheme.primary, Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:      AppTheme.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset:     const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Instrucciones de Pago',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transfiere el monto exacto de tu reserva mediante '
                  'QR al nÃºmero de cuenta del propietario. '
                  'Luego sube la foto de tu voucher o captura de pantalla del pago.',
                  style: TextStyle(
                    color:    Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    height:   1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Steps
          const Text(
            'Pasos a seguir',
            style: TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w700,
              color:      AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const _StepRow(number: '1', text: 'Abre tu app bancaria y escanea el cÃ³digo QR que te compartiÃ³ el propietario en el chat.'),
          const _StepRow(number: '2', text: 'Realiza la transferencia por el monto exacto de tu reserva.'),
          const _StepRow(number: '3', text: 'Toma una captura o foto del comprobante y cÃ¡rgala aquÃ­.'),
          const SizedBox(height: 28),

          // Voucher picker
          const Text(
            'Tu comprobante',
            style: TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w700,
              color:      AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: isLoading ? null : onPickTap,
            child: AnimatedContainer(
              duration:     const Duration(milliseconds: 200),
              width:        double.infinity,
              height:       200,
              decoration:   BoxDecoration(
                color: voucherFile != null ? Colors.transparent : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: voucherFile != null ? AppTheme.primary : AppTheme.border,
                  width: voucherFile != null ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: voucherFile != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(voucherFile!, fit: BoxFit.cover),
                        Positioned(
                          bottom: 10, right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:        Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Cambiar',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_rounded,
                            size: 40,
                            color: AppTheme.primary.withOpacity(0.7)),
                        const SizedBox(height: 10),
                        const Text(
                          'Toca para subir tu comprobante',
                          style: TextStyle(
                            color:      AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize:   14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CÃ¡mara o galerÃ­a Â· JPG, PNG',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Enviar Comprobante'),
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFFD97706), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El propietario verificarÃ¡ tu comprobante antes de confirmar la reserva.',
                    style: TextStyle(
                      fontSize: 12,
                      color:    Color(0xFF92400E),
                      height:   1.4,
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
}

// â”€â”€â”€ Tab 1: QR Sandbox â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SandboxQrTab extends ConsumerWidget {
  final String reservaId;
  const _SandboxQrTab({required this.reservaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sandboxPaymentProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // â”€â”€ Badge de modo sandbox â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color:        const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.developer_mode_rounded,
                    color: Color(0xFFD97706), size: 16),
                SizedBox(width: 6),
                Text(
                  'MODO SANDBOX â€” Solo para pruebas',
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF92400E),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // â”€â”€ TÃ­tulo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const Text(
            'Escanea para pagar con\nLibÃ©lula (Sandbox)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   22,
              fontWeight: FontWeight.w800,
              color:      AppTheme.textPrimary,
              height:     1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Este QR es generado dinÃ¡micamente por el servidor\n'
            'con los datos de tu reserva.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color:    AppTheme.textSecondary.withOpacity(0.8),
              height:   1.5,
            ),
          ),
          const SizedBox(height: 28),

          // â”€â”€ QR o loader â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            width:  280,
            height: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset:     const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.15),
                width: 2,
              ),
            ),
            child: state.isLoadingQr
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          color:       AppTheme.primary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Generando QR...',
                          style: TextStyle(
                            color:   AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : state.hasError && state.qrUrl == null
                    // Error al obtener el QR
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.error, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              state.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color:    AppTheme.error,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              icon:  const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reintentar'),
                              onPressed: () => ref
                                  .read(sandboxPaymentProvider.notifier)
                                  .generateQr(reservaId),
                            ),
                          ],
                        ),
                      )
                    // QR listo
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          state.qrUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_rounded,
                                size: 48, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 12),

          // ID de transacciÃ³n (Ãºtil para debugging)
          if (state.transaccionId != null)
            Text(
              'Tx: ${state.transaccionId}',
              style: const TextStyle(
                fontSize:      11,
                color:         AppTheme.textSecondary,
                fontFamily:    'monospace',
                letterSpacing: 0.5,
              ),
            ),

          const SizedBox(height: 32),

          // â”€â”€ BotÃ³n Simular Pago â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isLoadingQr || state.isSimulatingPay
                  ? null
                  : () => ref
                      .read(sandboxPaymentProvider.notifier)
                      .simulatePay(reservaId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669), // Emerald-600
                foregroundColor: Colors.white,
                padding:         const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF059669).withOpacity(0.4),
              ),
              icon: state.isSimulatingPay
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Icon(Icons.bolt_rounded, size: 22),
              label: Text(
                state.isSimulatingPay
                    ? 'Procesando pago...'
                    : 'Simular Pago  (Modo Sandbox)',
                style: const TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Error al simular
          if (state.hasError && !state.isLoadingQr)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: AppTheme.error.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color:    AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ExplicaciÃ³n del flujo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border:       Border.all(
                  color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: const Column(
              children: [
                _InfoRow(
                  icon:  Icons.looks_one_rounded,
                  text:  'El botÃ³n envÃ­a un POST al webhook /api/payments/webhook/libelula simulando al banco.',
                ),
                SizedBox(height: 8),
                _InfoRow(
                  icon:  Icons.looks_two_rounded,
                  text:  'El backend actualiza la reserva a PAGADA y emite el evento pago_exitoso por Socket.IO.',
                ),
                SizedBox(height: 8),
                _InfoRow(
                  icon:  Icons.looks_3_rounded,
                  text:  'Esta pantalla escucha ese evento y se cierra automÃ¡ticamente con un SnackBar verde.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Helper Widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26, height: 26,
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color:      AppTheme.primary,
                fontSize:   12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color:    AppTheme.textSecondary,
                  height:   1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:        onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color:      AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize:   14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color:    AppTheme.textSecondary,
              height:   1.5,
            ),
          ),
        ),
      ],
    );
  }
}
