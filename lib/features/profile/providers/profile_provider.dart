import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../../post/models/post.dart';
import '../models/profile_stats.dart';
import '../repositories/profile_repository.dart';

class ProfileWithStats {
  final Profile profile;
  final ProfileStats stats;
  final bool isFollowing;
  ProfileWithStats({
    required this.profile,
    required this.stats,
    required this.isFollowing,
  });
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final profileByUsernameProvider = FutureProvider.family<ProfileWithStats?, String>((ref, username) async {
  final repo = ref.watch(profileRepositoryProvider);
  final profile = await repo.getProfileByUsername(username);
  if (profile == null) return null;
  final stats = await repo.getProfileStats(profile.id);
  final currentUser = ref.watch(currentUserProvider);
  final isFollowing = currentUser != null
      ? await repo.isFollowing(currentUser.id, profile.id)
      : false;
  return ProfileWithStats(profile: profile, stats: stats, isFollowing: isFollowing);
});

final userPostsProvider = FutureProvider.family<List<Post>, String>((ref, userId) async {
  return ref.read(postRepositoryProvider).getUserPosts(userId);
});
