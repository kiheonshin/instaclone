import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'admin_router.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start from the centralized AppTheme and add admin-specific overrides.
    final base = AppTheme.lightTheme;

    return MaterialApp.router(
      title: 'Insta Clone 관리자',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        // Slightly elevated cards for the admin dashboard look.
        cardTheme: base.cardTheme.copyWith(elevation: 1),
      ),
      routerConfig: ref.watch(adminRouterProvider),
    );
  }
}
