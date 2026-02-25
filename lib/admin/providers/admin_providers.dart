import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/profile.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../models/analytics_event.dart';
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
