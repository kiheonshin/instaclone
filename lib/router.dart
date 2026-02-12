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
      // ─── 관리자 라우트 (MainLayout 밖) ───
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const AdminLoginScreen(),
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
      // ─── 인증 라우트 (MainLayout 밖) ───
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      // ─── 게시물 작성 (풀스크린, MainLayout 밖) ───
      GoRoute(
        path: '/create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      // ─── 게시물 상세 (풀스크린, MainLayout 밖) ───
      GoRoute(
        path: '/post/:id',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['id']!,
        ),
      ),
      // ─── 메인 레이아웃 라우트 ───
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
