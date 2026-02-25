import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics_event.dart';
import '../../features/auth/models/profile.dart';

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
    await _client
        .from('profiles')
        .update({'is_admin': isAdmin}).eq('id', userId);
  }

  Future<List<AnalyticsEvent>> getAnalyticsEvents({
    required DateTime from,
    DateTime? to,
    String? pageUrl,
    int limit = 5000,
  }) async {
    dynamic query = _client
        .from('analytics_events')
        .select()
        .gte('created_at', from.toUtc().toIso8601String());

    if (to != null) {
      query = query.lte('created_at', to.toUtc().toIso8601String());
    }
    if (pageUrl != null && pageUrl.isNotEmpty) {
      query = query.eq('page_url', pageUrl);
    }
    query = query.order('created_at', ascending: false).limit(limit);

    final res = await query;
    return (res as List)
        .map(
          (json) => AnalyticsEvent.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  Future<List<String>> getAnalyticsPages({
    required DateTime from,
    DateTime? to,
  }) async {
    dynamic query = _client
        .from('analytics_events')
        .select('page_url')
        .gte('created_at', from.toUtc().toIso8601String());

    if (to != null) {
      query = query.lte('created_at', to.toUtc().toIso8601String());
    }
    query = query.order('page_url', ascending: true).limit(5000);

    final res = await query;
    final uniquePages = <String>{};
    for (final row in res as List) {
      final pageUrl = (row as Map)['page_url'] as String?;
      if (pageUrl != null && pageUrl.isNotEmpty) {
        uniquePages.add(pageUrl);
      }
    }
    return uniquePages.toList()..sort();
  }
}
