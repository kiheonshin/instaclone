import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/models/profile.dart';
import '../../profile/providers/profile_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<Profile> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final results = await repo.searchUsers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '사용자 검색',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                _search(value);
              } else if (value.isEmpty) {
                setState(() => _results = []);
              }
            },
          ),
          const SizedBox(height: 24),
          if (_isSearching)
            Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            )
          else if (_results.isEmpty && _searchController.text.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    '검색 결과가 없습니다',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else if (_results.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: theme.colorScheme.outline.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    '사용자명을 검색하세요',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final profile = _results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile.avatarUrl != null
                          ? CachedNetworkImageProvider(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? Text(profile.username[0].toUpperCase())
                          : null,
                    ),
                    title: Text(profile.username),
                    subtitle: profile.fullName != null ? Text(profile.fullName!) : null,
                    onTap: () => context.go('/profile/${profile.username}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
