import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://garaje-backend-api.onrender.com';

  // Auth
  static const String register = '/api/users/register';
  static const String login = '/api/users/login';
  static const String googleAuth = '/api/users/google';
  static const String userProfile = '/api/users/profile';
  static const String verifyEmail = '/api/users/verify-email';
  static const String forgotPassword = '/api/users/forgot-password';
  static const String resetPassword = '/api/users/reset-password';
  static const String kyc = '/api/users/kyc';
  static String kycById(String id) => '/api/users/kyc/$id';
  static String approveKyc(String id) => '/api/users/approve/$id';

  // Garages
  static const String garages = '/api/garages';
  static const String myGarages = '/api/garages/me';
  static String garageHorarios(String id) => '/api/garages/$id/horarios';
  static String garageServicios(String id) => '/api/garages/$id/servicios';
  static String garageServicioAdicional(String idGaraje, String idServicio) =>
      '/api/garages/$idGaraje/servicios/$idServicio';
  static String garageBloquearFecha(String id) =>
      '/api/garages/$id/bloquear-fecha';
  static String garageImagenes(String id) => '/api/garages/$id/imagenes';

  // Search
  static const String search = '/api/search';

  // Reservations
  static const String reservations = '/api/reservations';
  static const String myReservations = '/api/reservations/me';
  static const String ownerReservations = '/api/reservations/owner';
  static String payReservation(String id) => '/api/reservations/$id/pagar';
  static String reservationById(String id) => '/api/reservations/$id';
  static String acceptForChat(String id) => '/api/reservations/$id/accept_chat';
  static String confirmReservation(String id) => '/api/reservations/$id/confirm';
  static String rejectReservation(String id) => '/api/reservations/$id/reject';

  // Operations
  static String checkIn(String id) => '/api/operations/$id/check-in';
  static String checkOut(String id) => '/api/operations/$id/check-out';

  // Finances
  static const String wallet = '/api/finances/billetera';
  static const String walletMovements = '/api/finances/billetera/movimientos';
  static const String withdrawal = '/api/finances/billetera/retiros';
  static String approveWithdrawal(String id) =>
      '/api/finances/billetera/retiros/$id/aprobar';

  // Support
  static const String tickets = '/api/support/tickets';
  static String dispute(String id) => '/api/support/reservas/$id/disputa';
  static String rate(String id) => '/api/support/reservas/$id/calificar';
  static String resolveTicket(String id) =>
      '/api/support/tickets/$id/resolver';

  // Chat
  static const String chatPresignedUrl = '/api/chat/presigned-url';
  static String chatHistory(String id) => '/api/chat/$id/mensajes';
  static String chatAttachment(String key) => '/api/chat/adjunto/$key';

  // Payments (Sandbox Libélula)
  static const String sandboxQr        = '/api/payments/sandbox/qr';
  static const String webhookLibelula   = '/api/payments/webhook/libelula';
}
