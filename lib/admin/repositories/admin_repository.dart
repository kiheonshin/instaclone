import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/models/profile.dart';
import '../../features/post/models/post.dart';

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  Future<List<Profile>> getAllUsers({int limit = 100}) async {
    final res = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (res as List).map((j) => Profile.fromJson(j)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllPosts({int limit = 100}) async {
    final res = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  Future<void> setAdmin(String userId, bool isAdmin) async {
    await _client.from('profiles').update({'is_admin': isAdmin}).eq('id', userId);
  }
}
