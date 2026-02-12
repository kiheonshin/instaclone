import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';

final postDetailProvider = FutureProvider.family<Post?, String>((ref, postId) async {
  final user = ref.watch(currentUserProvider);
  return ref.read(postRepositoryProvider).getPostById(postId, currentUserId: user?.id);
});

final postCommentsProvider = FutureProvider.family<List<Comment>, String>((ref, postId) async {
  return ref.read(postRepositoryProvider).getComments(postId);
});
