import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../auth/providers/auth_provider.dart';
import '../../../feed/providers/feed_provider.dart';
import 'package:insta_clone/theme/app_theme.dart';
import '../../models/post.dart';

class PostCard extends ConsumerWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onProfileTap,
    this.onCommentTap,
  });

  final Post post;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCommentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          leading: GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 18,
              backgroundImage: post.author?.avatarUrl != null
                  ? CachedNetworkImageProvider(post.author!.avatarUrl!)
                  : null,
              child: post.author?.avatarUrl == null
                  ? Text(post.author?.username[0].toUpperCase() ?? '?')
                  : null,
            ),
          ),
          title: GestureDetector(
            onTap: onProfileTap,
            child: Text(
              post.author?.username ?? '알 수 없음',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/post/${post.id}'),
          child: AspectRatio(
            aspectRatio: 1,
            child: CachedNetworkImage(
              imageUrl: post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Icon(Icons.error, size: 48),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _LikeButton(post: post, userId: user?.id),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: onCommentTap ?? () => context.go('/post/${post.id}'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_outlined),
                onPressed: () {},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
            ],
          ),
        ),
        if (post.likesCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '좋아요 ${post.likesCount}개',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        if (post.caption != null && post.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${post.author?.username ?? ''} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: post.caption),
                ],
              ),
            ),
          ),
        if (post.commentsCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
          onTap: onCommentTap ?? () => context.go('/post/${post.id}'),
          child: Text(
                '댓글 ${post.commentsCount}개 모두 보기',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            timeago.format(post.createdAt, locale: 'ko'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.post, this.userId});

  final Post post;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        post.isLiked ? Icons.favorite : Icons.favorite_border,
        color: post.isLiked ? AppTheme.instagramLikeRed : null,
      ),
      onPressed: userId == null ? null : () async {
        await ref.read(postRepositoryProvider).toggleLike(post.id, userId!);
        ref.invalidate(feedPostsProvider);
      },
    );
  }
}
