import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/profile.dart';
import '../models/profile_stats.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile?> getProfileByUsername(String username) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('username', username)
        .maybeSingle();
    if (res == null) return null;
    return Profile.fromJson(res);
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;
    if (updates.isEmpty) return;

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<ProfileStats> getProfileStats(String userId) async {
    final postsCount = await _client
        .from('posts')
        .select('id')
        .eq('user_id', userId);
    final followersCount = await _client
        .from('follows')
        .select('id')
        .eq('following_id', userId);
    final followingCount = await _client
        .from('follows')
        .select('id')
        .eq('follower_id', userId);

    return ProfileStats(
      postsCount: (postsCount as List).length,
      followersCount: (followersCount as List).length,
      followingCount: (followingCount as List).length,
    );
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    if (followerId == followingId) return false;
    final res = await _client
        .from('follows')
        .select('id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return res != null;
  }

  Future<void> follow(String followerId, String followingId) async {
    await _client.from('follows').insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollow(String followerId, String followingId) async {
    await _client.from('follows').delete().eq('follower_id', followerId).eq('following_id', followingId);
  }

  Future<List<Profile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await _client
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .limit(20);
    return (res as List).map((j) => Profile.fromJson(j)).toList();
  }
}
