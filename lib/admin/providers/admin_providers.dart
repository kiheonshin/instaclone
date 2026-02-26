import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/profile.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../models/analytics_event.dart';
import '../models/page_view.dart';
import '../repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final adminUsersProvider = FutureProvider<List<Profile>>((ref) async {
  return ref.read(adminRepositoryProvider).getAllUsers();
});

final adminPostsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getAllPosts();
});

enum AnalyticsDateFilter {
  today,
  sevenDays,
  thirtyDays,
}

extension AnalyticsDateFilterX on AnalyticsDateFilter {
  String get label {
    switch (this) {
      case AnalyticsDateFilter.today:
        return '오늘';
      case AnalyticsDateFilter.sevenDays:
        return '7일';
      case AnalyticsDateFilter.thirtyDays:
        return '30일';
    }
  }

  DateTime get from {
    final now = DateTime.now();
    switch (this) {
      case AnalyticsDateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsDateFilter.sevenDays:
        return now.subtract(const Duration(days: 7));
      case AnalyticsDateFilter.thirtyDays:
        return now.subtract(const Duration(days: 30));
    }
  }
}

final analyticsDateFilterProvider = StateProvider<AnalyticsDateFilter>((ref) {
  return AnalyticsDateFilter.today;
});

final analyticsSelectedPageProvider = StateProvider<String?>((ref) => null);

final adminAnalyticsPagesProvider = FutureProvider<List<String>>((ref) async {
  final dateFilter = ref.watch(analyticsDateFilterProvider);
  return ref
      .read(adminRepositoryProvider)
      .getAnalyticsPages(from: dateFilter.from);
});

final adminAnalyticsEventsProvider =
    FutureProvider<List<AnalyticsEvent>>((ref) async {
  final dateFilter = ref.watch(analyticsDateFilterProvider);
  final selectedPage = ref.watch(analyticsSelectedPageProvider);
  return ref.read(adminRepositoryProvider).getAnalyticsEvents(
        from: dateFilter.from,
        pageUrl: selectedPage,
      );
});

// ──────────────────────────────────────────────
//  Visitor Analytics providers
// ──────────────────────────────────────────────

/// Date filter specifically for the visitor analytics dashboard.
final visitorDateFilterProvider = StateProvider<AnalyticsDateFilter>((ref) {
  return AnalyticsDateFilter.thirtyDays;
});

/// Summary cards data (today vs yesterday, avg duration, bounce, top page).
/// Always uses today/yesterday regardless of date filter selection.
final visitorSummaryProvider = FutureProvider<VisitorSummary>((ref) async {
  return ref.read(adminRepositoryProvider).getVisitorSummary();
});

/// Daily visitor trend (unique sessions per day, last 30 days).
final dailyVisitorTrendProvider =
    FutureProvider<Map<String, int>>((ref) async {
  return ref.read(adminRepositoryProvider).getDailyVisitorCounts(days: 30);
});

/// Referrer distribution pie chart data.
final referrerDistributionProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final dateFilter = ref.watch(visitorDateFilterProvider);
  return ref
      .read(adminRepositoryProvider)
      .getReferrerDistribution(from: dateFilter.from);
});

/// Device type distribution (mobile/tablet/desktop).
final deviceDistributionProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final dateFilter = ref.watch(visitorDateFilterProvider);
  return ref
      .read(adminRepositoryProvider)
      .getDeviceDistribution(from: dateFilter.from);
});

/// Hourly visit distribution (0-23).
final hourlyDistributionProvider =
    FutureProvider<Map<int, int>>((ref) async {
  final dateFilter = ref.watch(visitorDateFilterProvider);
  return ref
      .read(adminRepositoryProvider)
      .getHourlyDistribution(from: dateFilter.from);
});

/// Top 5 pages by average dwell time.
final topPagesByDurationProvider =
    FutureProvider<List<PageDuration>>((ref) async {
  final dateFilter = ref.watch(visitorDateFilterProvider);
  return ref
      .read(adminRepositoryProvider)
      .getTopPagesByDuration(from: dateFilter.from);
});
