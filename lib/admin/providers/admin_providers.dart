import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/models/profile.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final adminUsersProvider = FutureProvider<List<Profile>>((ref) async {
  return ref.read(adminRepositoryProvider).getAllUsers();
});

final adminPostsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getAllPosts();
});
