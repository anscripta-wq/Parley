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
          SnackBar(content: Text('Could not publish post: $e')),
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
      await supabase.from('posts').update({'likes_count': nextLikes}).eq('id', post.id);
    } catch (_) {}
  }

  void _toggleSave(PostItem post) {
    final w = widget as PostsScreen;
    setState(() {
      post.isSaved = !post.isSaved;
    });
    w.onStateChange();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(post.isSaved ? 'Saved to your readings.' : 'Removed from saved.'),
        duration: const Duration(seconds: 1),
      ),
    );
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: w.onRefresh),
        ],
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
                                      TextButton.icon(
                                        onPressed: () => _toggleLike(post),
                                        icon: Icon(
                                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                                          size: 20,
                                          color: post.isLiked ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                        label: Text(
                                          post.likesCount == 0 ? 'Appreciate' : '${post.likesCount} Appreciations',
                                          style: TextStyle(
                                            color: post.isLiked ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
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
