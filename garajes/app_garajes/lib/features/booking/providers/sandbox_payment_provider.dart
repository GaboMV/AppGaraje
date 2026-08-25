import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import 'reservation_provider.dart';

// ─── State ───────────────────────────────────────────────────────────────────

/// Las tres fases del flujo de pago sandbox:
///   loadingQr    → POST /sandbox/qr en vuelo
///   qrReady      → QR disponible (o error al cargarlo)
///   simulatingPay → POST /webhook/libelula en vuelo
enum SandboxPhase { loadingQr, qrReady, simulatingPay }

class SandboxPaymentState {
  final SandboxPhase phase;
  final String? qrUrl;          // URL del QR generado por qrserver.com
  final String? transaccionId;  // ID simulado devuelto por el backend
  final String? errorMessage;

  const SandboxPaymentState({
    this.phase        = SandboxPhase.loadingQr,
    this.qrUrl,
    this.transaccionId,
    this.errorMessage,
  });

  SandboxPaymentState copyWith({
    SandboxPhase? phase,
    String? qrUrl,
    String? transaccionId,
    String? errorMessage,
  }) =>
      SandboxPaymentState(
        phase:         phase         ?? this.phase,
        qrUrl:         qrUrl         ?? this.qrUrl,
        transaccionId: transaccionId ?? this.transaccionId,
        errorMessage:  errorMessage,   // nullable reset intencional
      );

  bool get isLoadingQr     => phase == SandboxPhase.loadingQr;
  bool get isQrReady       => phase == SandboxPhase.qrReady;
  bool get isSimulatingPay => phase == SandboxPhase.simulatingPay;
  bool get hasError        => errorMessage != null;
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class SandboxPaymentNotifier
    extends AutoDisposeNotifier<SandboxPaymentState> {
  @override
  SandboxPaymentState build() => const SandboxPaymentState();

  /// Llama a POST /api/payments/sandbox/qr y almacena la URL del QR.
  /// Debe invocarse en initState de la pantalla.
  Future<void> generateQr(String reservaId) async {
    state = const SandboxPaymentState(phase: SandboxPhase.loadingQr);

    try {
      final response = await DioClient.instance.post(
        ApiConstants.sandboxQr,
        data: {'id_reserva': reservaId},
      );

      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(
        phase:         SandboxPhase.qrReady,
        qrUrl:         data['qr_url'] as String?,
        transaccionId: data['transaccion_id'] as String?,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        phase:        SandboxPhase.qrReady,
        errorMessage: ApiException.fromDio(e).message,
      );
    } catch (_) {
      state = state.copyWith(
        phase:        SandboxPhase.qrReady,
        errorMessage: 'No se pudo generar el QR. Intenta de nuevo.',
      );
    }
  }

  /// Simula el POST de confirmación que enviaría la pasarela real.
  /// El backend emitirá `pago_exitoso` por Socket.IO, que la pantalla
  /// escucha para hacer el pop automático.
  Future<void> simulatePay(String reservaId) async {
    if (state.isSimulatingPay) return;

    state = state.copyWith(
      phase:        SandboxPhase.simulatingPay,
      errorMessage: null,
    );

    try {
      await DioClient.instance.post(
        ApiConstants.webhookLibelula,
        data: {
          'id_reserva':     reservaId,
          'status':         'COMPLETED',
          'transaccion_id': state.transaccionId,
          'metodo':         'QR_LIBELULA',
        },
      );

      // Invalida cache para que la lista de reservas se refresque al volver.
      // El pop real lo dispara el listener de socket en la pantalla.
      ref.invalidate(myReservationsProvider);
      ref.invalidate(reservationDetailsProvider(reservaId));
    } on DioException catch (e) {
      state = state.copyWith(
        phase:        SandboxPhase.qrReady,
        errorMessage: ApiException.fromDio(e).message,
      );
    } catch (_) {
      state = state.copyWith(
        phase:        SandboxPhase.qrReady,
        errorMessage: 'Error al simular el pago. Intenta de nuevo.',
      );
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final sandboxPaymentProvider = AutoDisposeNotifierProvider<
    SandboxPaymentNotifier, SandboxPaymentState>(
  SandboxPaymentNotifier.new,
);

