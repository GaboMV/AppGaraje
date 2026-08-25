import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import 'reservation_provider.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum PaymentUploadStatus { idle, uploading, success, error }

class PaymentUploadState {
  final PaymentUploadStatus status;
  final String? errorMessage;

  const PaymentUploadState({
    this.status = PaymentUploadStatus.idle,
    this.errorMessage,
  });

  PaymentUploadState copyWith({
    PaymentUploadStatus? status,
    String? errorMessage,
  }) =>
      PaymentUploadState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get isLoading => status == PaymentUploadStatus.uploading;
  bool get isSuccess => status == PaymentUploadStatus.success;
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class PaymentUploadNotifier extends AutoDisposeNotifier<PaymentUploadState> {
  @override
  PaymentUploadState build() => const PaymentUploadState();

  /// Sube el comprobante como multipart y llama al endpoint de pago.
  /// El backend espera POST /api/reservations/:id/pagar con metodo_pago=QR.
  Future<void> submitVoucher({
    required String reservaId,
    required File voucherFile,
  }) async {
    state = state.copyWith(status: PaymentUploadStatus.uploading);

    try {
      final formData = FormData.fromMap({
        'metodo_pago': 'QR',
        'comprobante': await MultipartFile.fromFile(
          voucherFile.path,
          filename: 'comprobante_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      await DioClient.instance.post(
        ApiConstants.payReservation(reservaId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // Invalida el cache para que la UI refleje estado PAGADA
      ref.invalidate(reservationDetailsProvider(reservaId));
      ref.invalidate(myReservationsProvider);

      state = state.copyWith(status: PaymentUploadStatus.success);
    } on DioException catch (e) {
      final apiEx = ApiException.fromDio(e);
      state = state.copyWith(
        status: PaymentUploadStatus.error,
        errorMessage: apiEx.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: PaymentUploadStatus.error,
        errorMessage: 'Error inesperado. Intenta de nuevo.',
      );
    }
  }

  void reset() => state = const PaymentUploadState();
}

final paymentUploadProvider =
    AutoDisposeNotifierProvider<PaymentUploadNotifier, PaymentUploadState>(
  PaymentUploadNotifier.new,
);
