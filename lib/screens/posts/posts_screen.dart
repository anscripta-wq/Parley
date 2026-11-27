import '../../services/sound_service.dart';
import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/supabase_client.dart';

class PostsScreen extends StatefulWidget {
  final UserProfile currentProfile;
  final List posts;
  final bool isLoading;
  final Future Function() onRefresh;
  final VoidCallback onStateChange;

  const PostsScreen({
    super.key,
    required this.currentProfile,
    required this.posts,
    required this.isLoading,
    required this.onRefresh,
    required this.onStateChange,
  });

  @override
  State createState() => _PostsScreenState();
}

class _PostsScreenState extends State {
  final TextEditingController _postSearchController = TextEditingController();
  String _postSearchQuery = '';

  @override
  void dispose() {
    _postSearchController.dispose();
    super.dispose();
  }

  Future _createPost(String text) async {
    final w = widget as PostsScreen;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      await supabase.from('posts').insert({
        'user_id': w.currentProfile.id,
        'author_handle': w.currentProfile.handle,
        'content': trimmed,
        'likes_count': 0,
      });
      await w.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, duration: const Duration(seconds: 6), content: Text('Post Error: $e')),
        );
      }
    }
  }

  Future _toggleLike(PostItem post) async {
    final w = widget as PostsScreen;
    final nextLiked = !post.isLiked;
    final nextLikes = (post.likesCount + (nextLiked ? 1 : -1)).clamp(0, 999999);

    setState(() {
      post.isLiked = nextLiked;
      post.likesCount = nextLikes;
    });
    w.onStateChange();

    try {
      if (nextLiked) {
        await supabase.from('post_likes').upsert({
          'post_id': post.id,
          'user_id': w.currentProfile.id,
        });
      } else {
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', post.id)
            .eq('user_id', w.currentProfile.id);
      }
      await supabase.from('posts').update({'likes_count': nextLikes}).eq('id', post.id);
    } catch (_) {}
  }

  Future _toggleSave(PostItem post) async {
    final w = widget as PostsScreen;
    final nextSaved = !post.isSaved;

    setState(() {
      post.isSaved = nextSaved;
    });
    w.onStateChange();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nextSaved ? 'Saved to your readings.' : 'Removed from saved.'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      if (nextSaved) {
        await supabase.from('saved_posts').upsert({
          'post_id': post.id,
          'user_id': w.currentProfile.id,
        });
      } else {
        await supabase
            .from('saved_posts')
            .delete()
            .eq('post_id', post.id)
            .eq('user_id', w.currentProfile.id);
      }
    } catch (_) {}
  }

  Future _deletePost(PostItem post) async {
    final w = widget as PostsScreen;
    try {
      await supabase.from('posts').delete().eq('id', post.id);
      await w.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete post: $e')),
        );
      }
    }
  }

  void _openComments(PostItem post) {
    final w = widget as PostsScreen;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => _CommentsSheet(
        post: post,
        currentProfile: w.currentProfile,
        onCommentAdded: () {
          setState(() {
            post.commentsCount += 1;
          });
          w.onStateChange();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as PostsScreen;
    final filteredPosts = w.posts
        .where(
          (post) =>
              _postSearchQuery.isEmpty ||
              post.content.toLowerCase().contains(_postSearchQuery) ||
              post.authorHandle.toLowerCase().contains(_postSearchQuery),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Common Room'),
        
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _postSearchController,
              onChanged: (value) => setState(() => _postSearchQuery = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search discussions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _postSearchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _postSearchController.clear();
                          setState(() => _postSearchQuery = '');
                        },
                      ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: w.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: w.onRefresh,
                    child: filteredPosts.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('No posts yet. Be the first to share a thought!')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = filteredPosts[index] as PostItem;
                              final isMine = post.userId == w.currentProfile.id;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            child: Text(post.initial, style: const TextStyle(color: Colors.white)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(post.authorHandle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                Text(post.timeAgo, style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                              color: post.isSaved ? Theme.of(context).colorScheme.primary : Colors.grey,
                                            ),
                                            onPressed: () => _toggleSave(post),
                                          ),
                                          if (isMine)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                              onPressed: () => _deletePost(post),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        post.content,
                                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _toggleLike(post),
                                            icon: Icon(
                                              post.isLiked ? Icons.favorite : Icons.favorite_border,
                                              size: 20,
                                              color: post.isLiked ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
                                            ),
                                            label: Text(
                                              post.likesCount == 0 ? 'Appreciate' : '${post.likesCount}',
                                              style: TextStyle(
                                                color: post.isLiked ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () => _openComments(post),
                                            icon: const Icon(Icons.chat_bubble_outline, size: 19),
                                            label: Text(
                                              post.commentsCount == 0 ? 'Discuss' : '${post.commentsCount} Comments',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).cardColor,
            builder: (context) => _CreatePostSheet(onPost: _createPost),
          );
        },
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Write a Post', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3E2F2F),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final PostItem post;
  final UserProfile currentProfile;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({
    required this.post,
    required this.currentProfile,
    required this.onCommentAdded,
  });

  @override
  State createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State {
  final TextEditingController _commentController = TextEditingController();
  List _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future _loadComments() async {
    final w = widget as _CommentsSheet;
    try {
      final rows = await supabase
          .from('post_comments')
          .select()
          .eq('post_id', w.post.id)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _comments = (rows as List).map((r) => CommentItem.fromMap(r as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future _addComment() async {
    final w = widget as _CommentsSheet;
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _commentController.clear();

    try {
      await supabase.from('post_comments').insert({
        'post_id': w.post.id,
        'user_id': w.currentProfile.id,
        'author_handle': w.currentProfile.handle,
        'content': text,
      });
      w.onCommentAdded();
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(14.0),
              child: Text('Margin Notes & Replies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                  ? const Center(child: Text('No comments yet. Start the discussion!'))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final c = _comments[index] as CommentItem;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(c.initial, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(c.authorHandle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Text(c.timeAgo, style: TextStyle(fontSize: 11, color: Theme.of(context).disabledColor)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(c.content, style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      onSubmitted: (_) => _addComment(),
                      decoration: InputDecoration(
                        hintText: 'Add a margin note...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final Future Function(String) onPost;
  const _CreatePostSheet({required this.onPost});

  @override
  State createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as _CreatePostSheet;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Write a Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share a literary thought, a language question, or start a debate...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isPosting
                ? null
                : () async {
                    if (_controller.text.trim().isEmpty) return;
                    setState(() => _isPosting = true);
                    await w.onPost(_controller.text);
                    if (mounted) Navigator.pop(context);
                  },
            child: Text(_isPosting ? 'Publishing...' : 'Publish to the Feed'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
