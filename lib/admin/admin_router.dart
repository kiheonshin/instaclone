import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import 'presentation/admin_login_screen.dart';
import 'presentation/admin_dashboard_screen.dart';
import 'presentation/admin_users_screen.dart';
import 'presentation/admin_posts_screen.dart';
import 'presentation/admin_heatmap_screen.dart';
import 'presentation/admin_analytics_screen.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: '/admin',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final profile = profileAsync.valueOrNull;
      final isProfileLoading = profileAsync.isLoading;
      final isAdmin = profile?.isAdmin ?? false;

      if (state.matchedLocation == '/admin/login' ||
          state.matchedLocation == '/admin/login/') {
        if (isLoggedIn && isAdmin) return '/admin';
        return null;
      }

      if (!isLoggedIn) return '/admin/login';
      if (isProfileLoading) return null;
      if (!isAdmin) return '/admin/login';

      return null;
    },
    routes: [
      GoRoute(
        path: '/admin',
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const AdminLoginScreen(),
          ),
          GoRoute(
            path: '',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: 'posts',
            builder: (context, state) => const AdminPostsScreen(),
          ),
          GoRoute(
            path: 'heatmap',
            builder: (context, state) => const AdminHeatmapScreen(),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
        ],
      ),
    ],
  );
});
