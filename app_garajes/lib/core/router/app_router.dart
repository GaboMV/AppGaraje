import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/auth_method_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/mode_selection_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/search_results_screen.dart';
import '../../features/home/screens/garage_details_screen.dart';
import '../../features/booking/screens/booking_request_screen.dart';
import '../../features/booking/screens/chat_screen.dart';
import '../../features/booking/screens/rating_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/kyc_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';

// Route names
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const authMethod = '/auth-method';
  static const register = '/register';
  static const login = '/login';
  static const modeSelection = '/mode-selection';
  static const home = '/home';
  static const searchResults = '/search-results';
  static const garageDetails = '/garage-details';
  static const bookingRequest = '/booking-request';
  static const chat = '/chat/:reservationId';
  static const rating = '/rating/:reservationId';
  static const profile = '/profile';
  static const kyc = '/kyc';
  static const wallet = '/wallet';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      // Allow splash to handle its own logic
      if (state.matchedLocation == AppRoutes.splash) return null;
      if (state.matchedLocation == AppRoutes.onboarding) return null;
      if (state.matchedLocation == AppRoutes.authMethod) return null;
      if (state.matchedLocation == AppRoutes.register) return null;
      if (state.matchedLocation == AppRoutes.login) return null;
      if (state.matchedLocation == AppRoutes.modeSelection) return null;

      // Protected routes
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.valueOrNull != null;

      if (isLoading) return null;
      if (!isAuthenticated) return AppRoutes.onboarding;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (ctx, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.authMethod,
        builder: (ctx, state) => const AuthMethodScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (ctx, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.modeSelection,
        builder: (ctx, state) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (ctx, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.searchResults,
        builder: (ctx, state) => const SearchResultsScreen(),
      ),
      GoRoute(
        path: AppRoutes.garageDetails,
        builder: (ctx, state) => const GarageDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingRequest,
        builder: (ctx, state) => const BookingRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (ctx, state) {
          final reservationId = state.pathParameters['reservationId']!;
          return ChatScreen(reservationId: reservationId);
        },
      ),
      GoRoute(
        path: AppRoutes.rating,
        builder: (ctx, state) {
          final reservationId = state.pathParameters['reservationId']!;
          return RatingScreen(reservationId: reservationId);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (ctx, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.kyc,
        builder: (ctx, state) => const KycScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (ctx, state) => const WalletScreen(),
      ),
    ],
  );
});
