import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  XFile? _dniXFile;
  XFile? _selfieXFile;
  Uint8List? _dniBytes;
  Uint8List? _selfieBytes;
  bool _loading = false;
  bool _submitted = false;
  late final TextEditingController _telefonoCtrl;

  @override
  void initState() {
    super.initState();
    _telefonoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isDni) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded,
                color: AppTheme.primary),
            title: const Text('Cámara'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded,
                color: AppTheme.primary),
            title: const Text('Galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    );
    if (source == null) return;

    final img = await picker.pickImage(source: source, imageQuality: 85);
    if (img != null && mounted) {
      // Check size (max 5MB)
      final bytes = await img.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('La imagen es demasiado grande (máx. 5MB)'),
                backgroundColor: AppTheme.error),
          );
        }
        return;
      }

      setState(() {
        if (isDni) {
          _dniXFile = img;
          _dniBytes = bytes;
        } else {
          _selfieXFile = img;
          _selfieBytes = bytes;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_dniXFile == null || _selfieXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sube ambas fotos para continuar'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    final telefono = _telefonoCtrl.text.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r"^[67]\d{7}$").hasMatch(telefono)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Número de teléfono inválido (debe empezar con 6 o 7 y tener 8 dígitos)'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final formData = FormData.fromMap({
        'telefono': telefono,
        'dni_foto': kIsWeb
            ? MultipartFile.fromBytes(_dniBytes!, filename: 'dni.jpg')
            : await MultipartFile.fromFile(_dniXFile!.path,
                filename: 'dni.jpg'),
        'selfie': kIsWeb
            ? MultipartFile.fromBytes(_selfieBytes!, filename: 'selfie.jpg')
            : await MultipartFile.fromFile(_selfieXFile!.path,
                filename: 'selfie.jpg'),
      });
      await DioClient.instance.post(ApiConstants.kyc, data: formData);
      if (mounted) setState(() => _submitted = true);
      // Refresh profile in background to update global state
      ref.read(authProvider.notifier).refreshProfile();
    } on DioException catch (e) {
      if (mounted) {
        final data = e.response?.data;
        final msg = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : (data is Map && data['error'] != null)
                ? data['error'].toString()
                : 'Error al enviar los documentos';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error inesperado: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final isReviewing = user?.isPending ?? false;
    final isRejected = user?.isRejected ?? false;
    final isVerified = user?.isVerified ?? false;
    
    // Si ya está verificado, no debería estar aquí, pero por si acaso:
    if (isVerified) {
       return Scaffold(
         appBar: AppBar(title: const Text('Verificación')),
         body: const Center(child: Text('¡Ya estás verificado!')),
       );
    }

    final showStatusOverlay = _submitted || isReviewing || isRejected;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verificación de Identidad'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRejected ? AppTheme.error.withOpacity(0.05) : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isRejected ? AppTheme.error.withOpacity(0.3) : AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(isRejected ? Icons.warning_amber_rounded : Icons.shield_outlined,
                          color: isRejected ? AppTheme.error : AppTheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isRejected ? 'Verificación Rechazada' : '¿Por qué necesitamos esto?',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isRejected ? AppTheme.error : AppTheme.primary,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              isRejected 
                                ? 'El administrador rechazó tus documentos. Motivo: ${user?.motivoRechazoKyc ?? "Sin motivo especificado"}'
                                : 'La verificación KYC es necesaria para publicar y alquilar espacios en GarageSale.',
                              style: TextStyle(
                                  color: (isRejected ? AppTheme.error : AppTheme.primary).withOpacity(0.8),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                const Text('Teléfono de Contacto',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Necesitamos tu número para coordinar verificaciones.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  enabled: !showStatusOverlay || isRejected,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.primary),
                    hintText: 'Ej. 70012345',
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Foto del DNI',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Foto frontal y legible del documento de identidad.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                _PhotoUploader(
                  bytes: _dniBytes,
                  onTap: (showStatusOverlay && !isRejected) ? () {} : () => _pickImage(true),
                  icon: Icons.badge_outlined,
                  label: 'Subir foto del DNI',
                ),
                const SizedBox(height: 24),

                const Text('Selfie con DNI',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Sostén el DNI y tómate una selfie bien iluminada.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                _PhotoUploader(
                  bytes: _selfieBytes,
                  onTap: (showStatusOverlay && !isRejected) ? () {} : () => _pickImage(false),
                  icon: Icons.face_outlined,
                  label: 'Tomar selfie con DNI',
                ),
              ],
            ),
          ),

          // Submit (Hidden if already submitted/reviewing, but NOT if rejected - let them re-submit)
          if (!showStatusOverlay || isRejected)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    24, 12, 24, MediaQuery.of(context).padding.bottom + 12),
                color: Colors.white,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: isRejected ? ElevatedButton.styleFrom(backgroundColor: AppTheme.primary) : null,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(isRejected ? 'Re-enviar documentos' : 'Enviar para Verificación'),
                ),
              ),
            ),

          // Success/Reviewing overlay (NOT for rejected)
          if (showStatusOverlay && !isRejected)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          isReviewing
                              ? Icons.hourglass_top_rounded
                              : Icons.how_to_reg_rounded,
                          color: AppTheme.primary,
                          size: 56),
                    ),
                    const SizedBox(height: 24),
                    Text(
                        isReviewing
                            ? 'Documentos en Revisión'
                            : '¡Documentos enviados!',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 24)),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        isReviewing
                            ? 'Estamos revisando tus documentos de identidad. Este proceso suele tardar menos de 24 horas.'
                            : 'Revisaremos tu información en las próximas 24 horas. Te notificaremos cuando esté verificado.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 36),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Volver al perfil',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
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

class _PhotoUploader extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _PhotoUploader({
    required this.bytes,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bytes != null
                ? Colors.transparent
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bytes != null ? AppTheme.secondary : AppTheme.border,
              width: bytes != null ? 2 : 1,
              style: BorderStyle.solid,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: bytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 36, color: AppTheme.textSecondary),
                    const SizedBox(height: 8),
                    Text(label,
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Toca para seleccionar',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
        ),
      );
}
