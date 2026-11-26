import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../services/supabase_client.dart';
import '../../widgets/common_widgets.dart';

class UserProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final Future Function({
    required String handle,
    required String nativeLang,
    required String learningLang,
    required String bio,
  }) onUpdateProfile;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final List savedPosts;

  const UserProfileScreen({
    super.key,
    required this.profile,
    required this.onUpdateProfile,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.savedPosts,
  });

  @override
  State createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State {
  Future _showEditProfileDialog() async {
    final w = widget as UserProfileScreen;
    final handleCtrl = TextEditingController(text: w.profile.handle.replaceFirst('@', ''));
    final bioCtrl = TextEditingController(text: w.profile.bio);
    String native = w.profile.nativeLang;
    String learning = w.profile.learningLang;
    String error = '';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: handleCtrl,
                  decoration: const InputDecoration(labelText: 'Username', prefixText: '@'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: kSupportedLanguages.contains(native) ? native : 'English',
                  decoration: const InputDecoration(labelText: 'Native Language'),
                  items: kSupportedLanguages
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setModalState(() => native = (v ?? native).toString()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: kSupportedLanguages.contains(learning) ? learning : 'Spanish',
                  decoration: const InputDecoration(labelText: 'Learning Language'),
                  items: kSupportedLanguages
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setModalState(() => learning = (v ?? learning).toString()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final clean = handleCtrl.text.trim().toLowerCase().replaceFirst('@', '');
                if (clean.isEmpty) {
                  setModalState(() => error = 'Username cannot be empty.');
                  return;
                }
                try {
                  await w.onUpdateProfile(
                    handle: clean,
                    nativeLang: native,
                    learningLang: learning,
                    bio: bioCtrl.text.trim(),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on PostgrestException catch (e) {
                  setModalState(() {
                    error = e.code == '23505' ? 'That username is already taken.' : e.message;
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSavedReadings() {
    final w = widget as UserProfileScreen;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Readings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: w.savedPosts.isEmpty
                  ? const Center(child: Text('No bookmarked posts yet. Tap the bookmark icon on any post!'))
                  : ListView.builder(
                      itemCount: w.savedPosts.length,
                      itemBuilder: (context, index) {
                        final p = w.savedPosts[index] as PostItem;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(p.authorHandle, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(p.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as UserProfileScreen;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditProfileDialog),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 28),
            ParleyAvatar(profile: w.profile, radius: 48),
            const SizedBox(height: 14),
            Text(w.profile.handle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                w.profile.bio,
                style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 14, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Native Language'),
                      trailing: Text(w.profile.nativeLang, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.language, color: Theme.of(context).colorScheme.secondary),
                      title: const Text('Learning Language'),
                      trailing: Text(w.profile.learningLang, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.local_fire_department, color: Colors.orange.shade600),
                      title: const Text('Reading Streak'),
                      trailing: Text('${w.profile.streakCount} day(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.bookmarks_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Saved Readings'),
              trailing: Text('${w.savedPosts.length} saved', style: TextStyle(color: Theme.of(context).disabledColor)),
              onTap: _openSavedReadings,
            ),
            ListTile(
              leading: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.secondary),
              title: const Text('Night Reading Mode'),
              trailing: Switch(
                value: w.isDarkMode,
                onChanged: (_) => w.onToggleTheme(),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () async {
                    await supabase.auth.signOut();
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  child: const Text('Log Out'),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
