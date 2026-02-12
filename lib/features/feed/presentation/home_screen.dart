import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../post/models/post.dart';
import '../../post/providers/post_provider.dart';
import '../providers/feed_provider.dart';
import '../../post/presentation/widgets/post_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedPostsProvider);

    return feedAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyFeed();
        }
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return PostCard(
              post: posts[index],
              onProfileTap: () => context.go('/profile/${posts[index].author?.username ?? ''}'),
              onCommentTap: () => context.go('/post/${posts[index].id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('오류: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(feedPostsProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            '아직 피드가 비어있어요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '새 게시물을 올리거나 다른 사용자를 팔로우해보세요',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/create'),
            icon: const Icon(Icons.add),
            label: const Text('게시물 작성'),
          ),
        ],
      ),
    );
  }
}
