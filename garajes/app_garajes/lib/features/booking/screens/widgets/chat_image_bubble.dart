import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/reservation_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// Renders a single chat image attachment.
///
/// 1. Calls [chatAttachmentUrlProvider] to get a short-lived Presigned URL.
/// 2. Passes that URL to [CachedNetworkImage], which downloads the bytes
///    and persists them to the device disk. This means the image continues
///    to display even after the 5-minute Presigned URL expires.
/// 3. Shows a [Shimmer] skeleton while the URL is being fetched, and an
///    error icon if the request fails.
class ChatImageBubble extends ConsumerWidget {
  /// The R2 object key returned by the backend (e.g. "chat/abc123.jpg").
  final String attachmentKey;

  /// Whether the message belongs to the current user (affects border radius).
  final bool isMe;

  const ChatImageBubble({
    super.key,
    required this.attachmentKey,
    this.isMe = false,
  });

  static const double _imgWidth = 220;
  static const double _imgHeight = 180;
  static const double _radius = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(chatAttachmentUrlProvider(attachmentKey));

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(_radius),
        topRight: const Radius.circular(_radius),
        bottomLeft: Radius.circular(isMe ? _radius : 4),
        bottomRight: Radius.circular(isMe ? 4 : _radius),
      ),
      child: urlAsync.when(
        // ── Loading ─────────────────────────────────────────────────
        loading: () => Shimmer.fromColors(
          baseColor: const Color(0xFFE2E8F0),
          highlightColor: Colors.white,
          child: Container(
            width: _imgWidth,
            height: _imgHeight,
            color: const Color(0xFFE2E8F0),
          ),
        ),

        // ── Error ────────────────────────────────────────────────────
        error: (_, __) => Container(
          width: _imgWidth,
          height: _imgHeight,
          color: const Color(0xFFF1F5F9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded,
                  color: AppTheme.textSecondary, size: 36),
              const SizedBox(height: 6),
              Text(
                'No se pudo cargar\nla imagen',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),

        // ── Data ─────────────────────────────────────────────────────
        data: (url) => CachedNetworkImage(
          imageUrl: url,
          width: _imgWidth,
          height: _imgHeight,
          fit: BoxFit.cover,
          // Shimmer while bytes are downloading from the signed URL
          placeholder: (_, __) => Shimmer.fromColors(
            baseColor: const Color(0xFFE2E8F0),
            highlightColor: Colors.white,
            child: Container(
              width: _imgWidth,
              height: _imgHeight,
              color: const Color(0xFFE2E8F0),
            ),
          ),
          // Error shown if download fails after URL was obtained
          errorWidget: (_, __, ___) => Container(
            width: _imgWidth,
            height: _imgHeight,
            color: const Color(0xFFF1F5F9),
            child: Icon(Icons.broken_image_rounded,
                color: AppTheme.textSecondary, size: 36),
          ),
        ),
      ),
    );
  }
}
