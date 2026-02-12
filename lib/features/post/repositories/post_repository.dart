import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/profile.dart';
import '../models/comment.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository(this._client);

  final SupabaseClient _client;

  Future<List<Post>> getFeedPosts({String? userId, int limit = 20, int offset = 0}) async {
    final postsResponse = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final posts = postsResponse as List;
    if (posts.isEmpty) return [];

    final postIds = posts.map((p) => p['id'] as String).toList();
    final likedPostIds = userId != null && userId.isNotEmpty
        ? await _getLikedPostIds(userId, postIds)
        : <String>{};

    final List<Post> result = [];
    for (final json in posts) {
      final author = await _getProfile(json['user_id'] as String);
      final likesCount = await _getLikesCount(json['id'] as String);
      final commentsCount = await _getCommentsCount(json['id'] as String);
      result.add(Post.fromJson(
        json,
        author: author,
        isLiked: likedPostIds.contains(json['id']),
      ).copyWith(likesCount: likesCount, commentsCount: commentsCount));
    }
    return result;
  }

  Future<Set<String>> _getLikedPostIds(String userId, List<String> postIds) async {
    if (postIds.isEmpty) return {};
    final res = await _client
        .from('likes')
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);
    return (res as List).map((r) => r['post_id'] as String).toSet();
  }

  Future<Profile?> _getProfile(String userId) async {
    final res = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (res == null) return null;
    return Profile.fromJson(res);
  }

  Future<int> _getLikesCount(String postId) async {
    final res = await _client.from('likes').select('id').eq('post_id', postId);
    return (res as List).length;
  }

  Future<int> _getCommentsCount(String postId) async {
    final res = await _client.from('comments').select('id').eq('post_id', postId);
    return (res as List).length;
  }

  Future<Post?> getPostById(String postId, {String? currentUserId}) async {
    final response = await _client
        .from('posts')
        .select()
        .eq('id', postId)
        .maybeSingle();

    if (response == null) return null;

    final author = await _getProfile(response['user_id'] as String);
    bool isLiked = false;
    if (currentUserId != null) {
      final likeRes = await _client
          .from('likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();
      isLiked = likeRes != null;
    }
    final likesCount = await _getLikesCount(postId);
    final commentsCount = await _getCommentsCount(postId);

    return Post.fromJson(
      response,
      author: author,
      isLiked: isLiked,
    ).copyWith(likesCount: likesCount, commentsCount: commentsCount);
  }

  Future<String> createPost({
    required String userId,
    required String imagePath,
    String? caption,
  }) async {
    final publicUrl = _client.storage.from('posts').getPublicUrl(imagePath);
    final response = await _client.from('posts').insert({
      'user_id': userId,
      'image_url': publicUrl,
      'caption': caption,
    }).select('id').single();
    return response['id'] as String;
  }

  Future<void> deletePost(String postId, String userId) async {
    await _client.from('posts').delete().eq('id', postId).eq('user_id', userId);
  }

  Future<void> toggleLike(String postId, String userId) async {
    final existing = await _client
        .from('likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client.from('likes').delete().eq('id', existing['id']);
    } else {
      await _client.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  Future<List<Comment>> getComments(String postId) async {
    final response = await _client
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final List<Comment> result = [];
    for (final json in response as List) {
      final author = await _getProfile(json['user_id'] as String);
      result.add(Comment.fromJson(json, author: author));
    }
    return result;
  }

  Future<void> addComment(String postId, String userId, String content) async {
    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }

  Future<List<Post>> getUserPosts(String userId, {int limit = 50}) async {
    if (userId.isEmpty) return [];
    final response = await _client
        .from('posts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    final posts = response as List;
    final List<Post> result = [];
    for (final json in posts) {
      final author = await _getProfile(userId);
      final likesCount = await _getLikesCount(json['id'] as String);
      final commentsCount = await _getCommentsCount(json['id'] as String);
      result.add(Post.fromJson(json, author: author).copyWith(
        likesCount: likesCount,
        commentsCount: commentsCount,
      ));
    }
    return result;
  }
}
