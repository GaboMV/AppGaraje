import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  File? _dniFile;
  File? _selfieFile;
  bool _loading = false;
  bool _submitted = false;

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
      setState(() {
        if (isDni) {
          _dniFile = File(img.path);
        } else {
          _selfieFile = File(img.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_dniFile == null || _selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sube ambas fotos para continuar'),
            backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final formData = FormData.fromMap({
        'dni_foto': await MultipartFile.fromFile(_dniFile!.path,
            filename: 'dni.jpg'),
        'selfie': await MultipartFile.fromFile(_selfieFile!.path,
            filename: 'selfie.jpg'),
      });
      await DioClient.instance.post(ApiConstants.kyc, data: formData);
      if (mounted) setState(() => _submitted = true);
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
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: AppTheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('¿Por qué necesitamos esto?',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              'La verificación KYC es necesaria para publicar y alquilar espacios en GarageSale.',
                              style: TextStyle(
                                  color: AppTheme.primary.withOpacity(0.8),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                const Text('Foto del DNI',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Foto frontal y legible del documento de identidad.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                _PhotoUploader(
                  file: _dniFile,
                  onTap: () => _pickImage(true),
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
                  file: _selfieFile,
                  onTap: () => _pickImage(false),
                  icon: Icons.face_outlined,
                  label: 'Tomar selfie con DNI',
                ),
              ],
            ),
          ),

          // Submit
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
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Enviar para Verificación'),
              ),
            ),
          ),

          // Success overlay
          if (_submitted)
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
                      child: const Icon(Icons.how_to_reg_rounded,
                          color: AppTheme.primary, size: 56),
                    ),
                    const SizedBox(height: 24),
                    const Text('¡Documentos enviados!',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 24)),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Revisaremos tu información en las próximas 24 horas. Te notificaremos cuando esté verificado.',
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
  final File? file;
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _PhotoUploader({
    required this.file,
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
            color: file != null
                ? Colors.transparent
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: file != null ? AppTheme.secondary : AppTheme.border,
              width: file != null ? 2 : 1,
              style: BorderStyle.solid,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: file != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(file!, fit: BoxFit.cover),
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
