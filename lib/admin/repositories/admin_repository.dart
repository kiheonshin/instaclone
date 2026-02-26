import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics_event.dart';
import '../models/page_view.dart';
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

  // ──────────────────────────────────────────────
  //  Page Views (visitor analytics)
  // ──────────────────────────────────────────────

  Future<List<PageView>> getPageViews({
    required DateTime from,
    DateTime? to,
    int limit = 10000,
  }) async {
    dynamic query = _client
        .from('page_views')
        .select()
        .gte('created_at', from.toUtc().toIso8601String());

    if (to != null) {
      query = query.lte('created_at', to.toUtc().toIso8601String());
    }
    query = query.order('created_at', ascending: false).limit(limit);

    final res = await query;
    return (res as List)
        .map((json) => PageView.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Visitor summary data for the 4 top cards.
  Future<VisitorSummary> getVisitorSummary() async {
    final now = DateTime.now();
    // Use UTC for consistent comparison with Supabase timestamptz values
    final todayStartLocal = DateTime(now.year, now.month, now.day);
    final todayStartUtc = todayStartLocal.toUtc();
    final yesterdayStartUtc =
        todayStartLocal.subtract(const Duration(days: 1)).toUtc();

    // Fetch today + yesterday page views in one query
    final res = await _client
        .from('page_views')
        .select()
        .gte('created_at', yesterdayStartUtc.toIso8601String())
        .order('created_at', ascending: false)
        .limit(10000);

    final allViews = (res as List)
        .map((j) => PageView.fromJson(Map<String, dynamic>.from(j)))
        .toList();

    // Compare in UTC to avoid timezone mismatch
    final todayViews = allViews
        .where((v) {
          final utc = v.createdAt.toUtc();
          return utc.isAfter(todayStartUtc) ||
              utc.isAtSameMomentAs(todayStartUtc);
        })
        .toList();
    final yesterdayViews = allViews
        .where((v) {
          final utc = v.createdAt.toUtc();
          return utc.isAfter(yesterdayStartUtc) &&
              utc.isBefore(todayStartUtc);
        })
        .toList();

    // Unique sessions for today / yesterday
    final todaySessions = todayViews.map((v) => v.sessionId).toSet();
    final yesterdaySessions = yesterdayViews.map((v) => v.sessionId).toSet();

    // Average duration (today)
    final durationsToday = todayViews
        .where((v) => v.durationSeconds != null && v.durationSeconds! > 0)
        .map((v) => v.durationSeconds!)
        .toList();
    final avgDuration = durationsToday.isEmpty
        ? 0.0
        : durationsToday.reduce((a, b) => a + b) / durationsToday.length;

    // Bounce rate: sessions with only 1 page view
    double bounceRate = 0.0;
    if (todaySessions.isNotEmpty) {
      final sessionPageCounts = <String, int>{};
      for (final v in todayViews) {
        sessionPageCounts[v.sessionId] =
            (sessionPageCounts[v.sessionId] ?? 0) + 1;
      }
      final bounceSessions =
          sessionPageCounts.values.where((c) => c == 1).length;
      bounceRate = (bounceSessions / sessionPageCounts.length) * 100;
    }

    // Most viewed page (today)
    final pageCount = <String, int>{};
    for (final v in todayViews) {
      pageCount[v.pageUrl] = (pageCount[v.pageUrl] ?? 0) + 1;
    }
    String topPage = '-';
    int topPageViews = 0;
    pageCount.forEach((page, count) {
      if (count > topPageViews) {
        topPage = page;
        topPageViews = count;
      }
    });

    return VisitorSummary(
      todayCount: todaySessions.length,
      yesterdayCount: yesterdaySessions.length,
      avgDurationSeconds: avgDuration,
      bounceRate: bounceRate,
      topPage: topPage,
      topPageViews: topPageViews,
    );
  }

  /// Daily visitor counts (unique sessions) for the last N days.
  Future<Map<String, int>> getDailyVisitorCounts({int days = 30}) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final res = await _client
        .from('page_views')
        .select('session_id, created_at')
        .gte('created_at', from.toUtc().toIso8601String())
        .order('created_at', ascending: true)
        .limit(50000);

    final dailySessions = <String, Set<String>>{};
    for (final row in res as List) {
      final createdAt =
          DateTime.tryParse(row['created_at'] as String? ?? '') ?? now;
      final dateKey =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      final sid = row['session_id'] as String? ?? '';
      dailySessions.putIfAbsent(dateKey, () => <String>{}).add(sid);
    }

    // Ensure all days are present (fill zeros)
    final result = <String, int>{};
    for (int i = 0; i < days; i++) {
      final d = from.add(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      result[key] = dailySessions[key]?.length ?? 0;
    }
    return result;
  }

  /// Referrer distribution grouped by domain.
  Future<Map<String, int>> getReferrerDistribution({
    required DateTime from,
  }) async {
    final res = await _client
        .from('page_views')
        .select('referrer')
        .gte('created_at', from.toUtc().toIso8601String())
        .limit(20000);

    final counts = <String, int>{};
    for (final row in res as List) {
      final ref = row['referrer'] as String? ?? '';
      String label;
      if (ref.isEmpty) {
        label = 'Direct';
      } else {
        try {
          label = Uri.parse(ref).host;
          if (label.isEmpty) label = 'Direct';
          // Simplify common referrers
          if (label.contains('google')) {
            label = 'Google';
          } else if (label.contains('facebook') || label.contains('fb.')) {
            label = 'Facebook';
          } else if (label.contains('instagram')) {
            label = 'Instagram';
          } else if (label.contains('twitter') || label.contains('t.co')) {
            label = 'Twitter/X';
          } else if (label.contains('naver')) {
            label = 'Naver';
          } else if (label.contains('youtube')) {
            label = 'YouTube';
          }
        } catch (_) {
          label = 'Other';
        }
      }
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts;
  }

  /// Device type distribution (mobile / tablet / desktop).
  Future<Map<String, int>> getDeviceDistribution({
    required DateTime from,
  }) async {
    final res = await _client
        .from('page_views')
        .select('device_type')
        .gte('created_at', from.toUtc().toIso8601String())
        .limit(20000);

    final counts = <String, int>{};
    for (final row in res as List) {
      final dt = row['device_type'] as String? ?? 'unknown';
      counts[dt] = (counts[dt] ?? 0) + 1;
    }
    return counts;
  }

  /// Hourly distribution (0-23).
  Future<Map<int, int>> getHourlyDistribution({
    required DateTime from,
  }) async {
    final res = await _client
        .from('page_views')
        .select('created_at')
        .gte('created_at', from.toUtc().toIso8601String())
        .limit(20000);

    final counts = <int, int>{};
    for (int h = 0; h < 24; h++) {
      counts[h] = 0;
    }
    for (final row in res as List) {
      final dt =
          DateTime.tryParse(row['created_at'] as String? ?? '');
      if (dt != null) {
        final localHour = dt.toLocal().hour;
        counts[localHour] = (counts[localHour] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Top pages by average dwell time.
  Future<List<PageDuration>> getTopPagesByDuration({
    required DateTime from,
    int limit = 5,
  }) async {
    final res = await _client
        .from('page_views')
        .select('page_url, duration_seconds')
        .gte('created_at', from.toUtc().toIso8601String())
        .not('duration_seconds', 'is', null)
        .gt('duration_seconds', 0)
        .limit(20000);

    final pageDurations = <String, List<double>>{};
    for (final row in res as List) {
      final page = row['page_url'] as String? ?? '';
      final dur = (row['duration_seconds'] is num)
          ? (row['duration_seconds'] as num).toDouble()
          : double.tryParse(row['duration_seconds']?.toString() ?? '') ?? 0.0;
      if (page.isNotEmpty && dur > 0) {
        pageDurations.putIfAbsent(page, () => []).add(dur);
      }
    }

    final results = pageDurations.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return PageDuration(
        pageUrl: e.key,
        avgDurationSeconds: avg,
        viewCount: e.value.length,
      );
    }).toList()
      ..sort((a, b) => b.avgDurationSeconds.compareTo(a.avgDurationSeconds));

    return results.take(limit).toList();
  }
}
