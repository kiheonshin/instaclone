import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:insta_clone/analytics/tracker_bridge.dart';

import '../../features/auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insta Clone 관리자'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: Icon(
              Icons.home_outlined,
              size: 20,
              color: theme.colorScheme.onPrimary,
            ),
            label: Text(
              '메인으로',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                profile?.username ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.onPrimary),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go('/admin/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _AdminCard(
              icon: Icons.people,
              title: '사용자 관리',
              subtitle: '전체 사용자 조회 및 권한 관리',
              onTap: () {
                AnalyticsTrackerBridge.trackCta('admin_go_users');
                context.go('/admin/users');
              },
            ),
            _AdminCard(
              icon: Icons.photo_library,
              title: '게시물 관리',
              subtitle: '전체 게시물 조회 및 삭제',
              onTap: () {
                AnalyticsTrackerBridge.trackCta('admin_go_posts');
                context.go('/admin/posts');
              },
            ),
            _AdminCard(
              icon: Icons.insights_outlined,
              title: 'Heatmap Analytics',
              subtitle: '클릭/스크롤/세션 리플레이',
              onTap: () {
                AnalyticsTrackerBridge.trackCta('admin_go_heatmap');
                context.go('/admin/heatmap');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
