import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/feed/presentation/home_screen.dart';
import 'features/post/presentation/create_post_screen.dart';
import 'features/post/presentation/post_detail_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
import 'features/search/presentation/search_screen.dart';
import 'shared/layout/main_layout.dart';
import 'admin/presentation/admin_login_screen.dart';
import 'admin/presentation/admin_dashboard_screen.dart';
import 'admin/presentation/admin_users_screen.dart';
import 'admin/presentation/admin_posts_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAdminRoute = loc.startsWith('/admin');
      final isAdminLogin = loc == '/admin/login' || loc == '/admin/login/';

      if (isAdminRoute) {
        final isLoggedIn = authState.valueOrNull != null;
        final profile = profileAsync.valueOrNull;
        final isProfileLoading = profileAsync.isLoading;
        final isAdmin = profile?.isAdmin ?? false;

        if (isAdminLogin) {
          if (isLoggedIn && isAdmin) return '/admin';
          return null;
        }
        if (!isLoggedIn) return '/admin/login';
        if (isProfileLoading) return null;
        if (!isAdmin) return '/admin/login';
        return null;
      }

      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = loc == '/login' || loc == '/signup';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
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
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/create',
            builder: (context, state) => const CreatePostScreen(),
          ),
          GoRoute(
            path: '/post/:id',
            builder: (context, state) => PostDetailScreen(
              postId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/profile/:username',
            builder: (context, state) => ProfileScreen(
              username: state.pathParameters['username']!,
            ),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
        ],
      ),
    ],
  );
});
