import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/auth/models/profile.dart';
import '../providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 관리'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 사용자가 없습니다',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(user.username[0].toUpperCase())
                        : null,
                  ),
                  title: Text(user.username),
                  subtitle: Text(user.fullName ?? user.id.substring(0, 8)),
                  trailing: user.isAdmin
                      ? Chip(
                          label: Text(
                            '관리자',
                            style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                ),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                        )
                      : null,
                ),
              );
            },
          ),
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }
}
