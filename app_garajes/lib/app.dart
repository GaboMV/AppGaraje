import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/global_socket_provider.dart';
import 'core/providers/location_provider.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class GarageSaleApp extends ConsumerStatefulWidget {
  const GarageSaleApp({super.key});

  @override
  ConsumerState<GarageSaleApp> createState() => _GarageSaleAppState();
}

class _GarageSaleAppState extends ConsumerState<GarageSaleApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(locationProvider.notifier).determinePosition());
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the global socket connection
    ref.watch(globalSocketProvider);

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'GarageSale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
    );
  }
}
