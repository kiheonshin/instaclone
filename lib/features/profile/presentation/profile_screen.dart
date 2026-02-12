import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByUsernameProvider(username));
    final profileId = profileAsync.valueOrNull?.profile.id ?? '';
    final postsAsync = ref.watch(userPostsProvider(profileId));

    return profileAsync.when(
      data: (data) {
        if (data == null) {
          return const Center(child: Text('사용자를 찾을 수 없습니다'));
        }
        final profile = data.profile;
        final stats = data.stats;
        final isFollowing = data.isFollowing;
        final currentUser = ref.watch(currentUserProvider);
        final isOwnProfile = currentUser?.id == profile.id;

        final theme = Theme.of(context);
        return SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header (centered - HTML design)
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 24, left: 24, right: 24),
                child: Column(
                  children: [
                    // Avatar with gradient border
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFBBF24),
                            Color(0xFFEF4444),
                            Color(0xFF9333EA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage: profile.avatarUrl != null
                              ? CachedNetworkImageProvider(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null
                              ? Text(
                                  profile.username[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 36),
                                )
                              : null,
                        ),
                      ),
                    ),
                    // Username & Bio (centered)
                    Text(
                      profile.username,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.bio!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Statistics Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),
                          bottom: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(count: stats.postsCount, label: '게시물', theme: theme),
                          _StatItem(count: stats.followersCount, label: '팔로워', theme: theme),
                          _StatItem(count: stats.followingCount, label: '팔로잉', theme: theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Action Button (slate-100 style)
                    SizedBox(
                      width: double.infinity,
                      child: isOwnProfile
                          ? TextButton(
                              onPressed: () => context.go('/profile/edit'),
                              style: TextButton.styleFrom(
                                backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                foregroundColor: theme.colorScheme.onSurface,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('프로필 편집'),
                            )
                          : _FollowButton(
                              isFollowing: isFollowing,
                              followerId: currentUser!.id,
                              followingId: profile.id,
                              username: username,
                            ),
                    ),
                  ],
                ),
              ),
              // Tab Indicator (grid on, person_pin)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.onSurface,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.grid_on,
                          size: 24,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Icon(
                        Icons.person_pin_outlined,
                        size: 24,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Content Grid (3-column, gap 0.5)
              postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 64,
                            color: theme.colorScheme.outline.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '아직 게시물이 없습니다',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 1,
                    ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return GestureDetector(
                        onTap: () => context.go('/post/${post.id}'),
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(Icons.error_outline),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  ),
                ),
                error: (e, _) => Text('로드 실패: $e'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label, required this.theme});

  final int count;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : count.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({
    required this.isFollowing,
    required this.followerId,
    required this.followingId,
    required this.username,
  });

  final bool isFollowing;
  final String followerId;
  final String followingId;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: () async {
        final repo = ref.read(profileRepositoryProvider);
        if (isFollowing) {
          await repo.unfollow(followerId, followingId);
        } else {
          await repo.follow(followerId, followingId);
        }
        ref.invalidate(profileByUsernameProvider(username));
      },
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(isFollowing ? '언팔로우' : '팔로우'),
    );
  }
}
