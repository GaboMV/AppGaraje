import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://garaje-backend-api.onrender.com';

  // Auth
  static const String register = '/api/users/register';
  static const String login = '/api/users/login';
  static const String googleAuth = '/api/users/google';
  static const String userProfile = '/api/users/profile';
  static const String kyc = '/api/users/kyc';
  static String kycById(String id) => '/api/users/kyc/$id';
  static String approveKyc(String id) => '/api/users/approve/$id';

  // Garages
  static const String garages = '/api/garages';
  static const String myGarages = '/api/garages/me';
  static String garageHorarios(String id) => '/api/garages/$id/horarios';
  static String garageServicios(String id) => '/api/garages/$id/servicios';
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

  // Operations
  static String checkIn(String id) => '/api/operations/$id/check-in';
  static String checkOut(String id) => '/api/operations/$id/check-out';

  // Finances
  static const String wallet = '/api/finances/billetera';
  static const String withdrawal = '/api/finances/billetera/retiros';
  static String approveWithdrawal(String id) =>
      '/api/finances/billetera/retiros/$id/aprobar';

  // Support
  static String dispute(String id) => '/api/support/reservas/$id/disputa';
  static String rate(String id) => '/api/support/reservas/$id/calificar';
  static String resolveTicket(String id) =>
      '/api/support/tickets/$id/resolver';

  // Chat
  static const String chatPresignedUrl = '/api/chat/presigned-url';
}
