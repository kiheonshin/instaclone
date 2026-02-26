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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w > 900 ? 4 : w > 560 ? 2 : 1;
              final hPad = w > 900 ? 32.0 : w > 560 ? 20.0 : 16.0;
              final ratio = w > 900 ? 2.0 : w > 560 ? 1.8 : 2.8;

              return GridView.count(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                crossAxisCount: cols,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: ratio,
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
                  _AdminCard(
                    icon: Icons.analytics_outlined,
                    title: '방문자 분석',
                    subtitle: '트래픽/유입경로/디바이스/체류시간',
                    onTap: () {
                      AnalyticsTrackerBridge.trackCta('admin_go_analytics');
                      context.go('/admin/analytics');
                    },
                  ),
                ],
              );
            },
          ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
