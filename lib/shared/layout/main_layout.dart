import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'package:insta_clone/theme/app_theme.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.child, this.location = '/'});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      body: Row(
        children: [
          if (isWide) ...[
            _NavSidebar(location: location),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 630),
                child: child,
              ),
            ),
          ),
          if (isWide) ...[
            const VerticalDivider(width: 1),
            const SizedBox(
              width: 320,
              child: _RightSidebar(),
            ),
          ],
        ],
      ),
      bottomNavigationBar: isWide ? null : _BottomNavBar(location: location),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar({required this.location});

  final String location;

  int _getSelectedIndex(WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final hasAdmin = profile?.isAdmin == true;
    if (location == '/') return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/create')) return 2;
    if (location.startsWith('/admin')) return hasAdmin ? 4 : 3;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final theme = Theme.of(context);
    final hasAdmin = profile?.isAdmin == true;
    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getSelectedIndex(ref),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '홈'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          const BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box), label: '만들기'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: '프로필'),
          if (hasAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: '관리자',
            ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/search');
              break;
            case 2:
              context.go('/create');
              break;
            case 3:
              if (profile != null) context.go('/profile/${profile.username}');
              break;
            case 4:
              if (hasAdmin) context.go('/admin');
              break;
          }
        },
      ),
    );
  }
}

class _NavSidebar extends ConsumerWidget {
  const _NavSidebar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    return Container(
      width: 244,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 0, 24),
            child: _InstagramLogo(),
          ),
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: '홈',
            isActive: location == '/',
            onTap: () => context.go('/'),
          ),
          _NavItem(
            icon: Icons.search,
            label: '검색',
            isActive: location.startsWith('/search'),
            onTap: () => context.go('/search'),
          ),
          _NavItem(
            icon: Icons.add_box_outlined,
            activeIcon: Icons.add_box,
            label: '만들기',
            isActive: location.startsWith('/create'),
            onTap: () => context.go('/create'),
          ),
          if (profile?.isAdmin == true) ...[
            _NavItem(
              icon: Icons.admin_panel_settings_outlined,
              activeIcon: Icons.admin_panel_settings,
              label: '관리자',
              isActive: location.startsWith('/admin'),
              onTap: () => context.go('/admin'),
            ),
          ],
          const Spacer(),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: '프로필',
            isActive: location.startsWith('/profile'),
            onTap: () {
              if (profile != null) {
                context.go('/profile/${profile.username}');
              }
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _InstagramLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          AppTheme.instagramPurple,
          AppTheme.instagramRed,
          AppTheme.instagramOrange,
          AppTheme.instagramYellow,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'Insta Clone',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.activeIcon,
    this.isActive = false,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        isActive && activeIcon != null ? activeIcon! : icon,
        size: 28,
        color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _RightSidebar extends ConsumerWidget {
  const _RightSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(profile.username[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (profile.fullName != null)
                      Text(
                        profile.fullName!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go('/profile/edit'),
                child: const Text('전환'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '팔로우 추천',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '곧 추가될 예정입니다',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
