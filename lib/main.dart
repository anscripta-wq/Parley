import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/app_models.dart';
import 'services/sound_service.dart';
import 'services/supabase_client.dart';
import 'screens/auth/auth_screens.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/partners/partners_screen.dart';
import 'screens/practice/practice_screen.dart';
import 'screens/posts/posts_screen.dart';
import 'screens/profile/profile_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://wofalpepdexhfzklqmdi.supabase.co',
    anonKey: 'sb_publishable_MDEwz1xdXjhx6Jr_Pu9s-Q_QrozJQF0',
  );
  runApp(const ParleyApp());
}

class ParleyApp extends StatefulWidget {
  const ParleyApp({super.key});
  @override
  State createState() => _ParleyAppState();
}

class _ParleyAppState extends State {
  bool _isDarkMode = false;

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  @override
  Widget build(BuildContext context) {
    const Color paperColor = Color(0xFFF9F6F0);
    const Color forestGreen = Color(0xFF2C5E4E);
    const Color inkBrown = Color(0xFF3E2F2F);
    const Color darkWood = Color(0xFF1E1A18);
    const Color darkPaper = Color(0xFF2A2422);
    const Color lightInk = Color(0xFFE0D8D0);
    const Color lightGreen = Color(0xFF4A8B76);

    return MaterialApp(
      title: 'Parley',
      theme: ThemeData(
        scaffoldBackgroundColor: _isDarkMode ? darkWood : paperColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _isDarkMode ? lightGreen : forestGreen,
          primary: _isDarkMode ? lightGreen : forestGreen,
          secondary: _isDarkMode ? lightInk : inkBrown,
          surface: _isDarkMode ? darkPaper : paperColor,
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Georgia',
        appBarTheme: AppBarTheme(
          backgroundColor: _isDarkMode ? darkWood : paperColor,
          foregroundColor: _isDarkMode ? lightInk : inkBrown,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold, color: _isDarkMode ? lightInk : inkBrown),
        ),
        cardTheme: CardThemeData(
          color: _isDarkMode ? darkPaper : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _isDarkMode ? lightInk.withValues(alpha: 0.1) : inkBrown.withValues(alpha: 0.1), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDarkMode ? lightGreen : forestGreen,
            foregroundColor: _isDarkMode ? darkWood : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: AuthGate(isDarkMode: _isDarkMode, onToggleTheme: _toggleTheme),
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  const AuthGate({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final data = snapshot.data as AuthState?;
        final session = data?.session ?? supabase.auth.currentSession;
        if (session == null) return const WelcomeScreen();
        return ProfileResolverScreen(
          key: ValueKey(session.user.id),
          user: session.user,
          isDarkMode: isDarkMode,
          onToggleTheme: onToggleTheme,
        );
      },
    );
  }
}

class ProfileResolverScreen extends StatefulWidget {
  final User user;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  const ProfileResolverScreen({super.key, required this.user, required this.isDarkMode, required this.onToggleTheme});
  @override
  State createState() => _ProfileResolverScreenState();
}

class _ProfileResolverScreenState extends State {
  late Future _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future _fetchProfile() async {
    final w = widget as ProfileResolverScreen;
    final data = await supabase.from('profiles').select().eq('id', w.user.id).maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as ProfileResolverScreen;
    return FutureBuilder(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final profile = snapshot.data as UserProfile?;
        if (profile == null) {
          return OnboardingScreen(
            user: w.user,
            onProfileSaved: (_) => setState(() => _profileFuture = _fetchProfile()),
          );
        }
        return MainScreen(profile: profile, isDarkMode: w.isDarkMode, onToggleTheme: w.onToggleTheme);
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final UserProfile profile;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  const MainScreen({super.key, required this.profile, required this.isDarkMode, required this.onToggleTheme});
  @override
  State createState() => _MainScreenState();
}

class _MainScreenState extends State {
  int _currentIndex = 0;
  int _unreadCount = 0;
  late UserProfile _profile;
  List _posts = [];
  bool _isLoadingPosts = true;
  RealtimeChannel? _alertChannel;

  @override
  void initState() {
    super.initState();
    _profile = (widget as MainScreen).profile;
    supabase.from('profiles').update({'last_active_date': DateTime.now().toUtc().toIso8601String().split('T').first}).eq('id', _profile.id).then((_) {});
    _loadPosts();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_alertChannel != null) supabase.removeChannel(_alertChannel!);
    super.dispose();
  }

  void _subscribeRealtime() {
    final myId = _profile.id;
    _alertChannel = supabase.channel('live_hub_$myId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final r = payload.newRecord;
          if (r['receiver_id'] == myId && mounted) {
            SoundService.playMessageChime();
            if (_currentIndex != 0) setState(() => _unreadCount += 1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.primary,
                content: Text('New letter: ${r['text'] ?? 'Voice Note'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                action: SnackBarAction(label: 'Open', textColor: Colors.white, onPressed: () => setState(() { _currentIndex = 0; _unreadCount = 0; })),
              ),
            );
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'posts',
        callback: (payload) {
          if (mounted) {
            if (payload.eventType == PostgresChangeEvent.insert && payload.newRecord['user_id'] != myId) {
              SoundService.playMessageChime();
            }
            _loadPosts();
          }
        },
      )
      .subscribe();
  }

  Future _loadPosts() async {
    try {
      final rows = await supabase.from('posts').select().order('created_at', ascending: false);
      final blockRows = await supabase.from('blocked_users').select('blocked_id').eq('blocker_id', _profile.id);
      final blockedIds = (blockRows as List).map((r) => (r as Map)['blocked_id'].toString()).toSet();
      final likeRows = await supabase.from('post_likes').select('post_id').eq('user_id', _profile.id);
      final saveRows = await supabase.from('saved_posts').select('post_id').eq('user_id', _profile.id);
      final commentRows = await supabase.from('post_comments').select('post_id');

      final likedIds = (likeRows as List).map((r) => (r as Map)['post_id'].toString()).toSet();
      final savedIds = (saveRows as List).map((r) => (r as Map)['post_id'].toString()).toSet();
      final commentCounts = {};
      for (final r in (commentRows as List)) {
        final pid = (r as Map)['post_id'].toString();
        commentCounts[pid] = (commentCounts[pid] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _posts = (rows as List)
              .where((row) => !blockedIds.contains((row as Map)['user_id'].toString()))
              .map((row) {
                final item = PostItem.fromMap(row as Map);
                item.isLiked = likedIds.contains(item.id);
                item.isSaved = savedIds.contains(item.id);
                item.commentsCount = (commentCounts[item.id] as int?) ?? 0;
                return item;
              }).toList();
          _isLoadingPosts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future _updateProfile({
    required String handle,
    required String gender,
    required String country,
    required String nativeLang,
    required String learningLang,
    required String bio,
    String? avatarUrl,
  }) async {
    final clean = handle.trim().toLowerCase().replaceFirst('@', '');
    final formatted = '@$clean';
    await supabase.from('profiles').update({
      'handle': formatted,
      'gender': gender,
      'country': country,
      'native_lang': nativeLang,
      'learning_lang': learningLang,
      'bio': bio,
      'avatar_url': avatarUrl ?? _profile.avatarUrl,
    }).eq('id', _profile.id);

    if (mounted) {
      setState(() {
        _profile = UserProfile(
          id: _profile.id,
          handle: formatted,
          gender: gender,
          country: country,
          nativeLang: nativeLang,
          learningLang: learningLang,
          bio: bio,
          avatarUrl: avatarUrl ?? _profile.avatarUrl,
          streakCount: _profile.streakCount,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as MainScreen;
    final screens = [
      MessagesScreen(currentProfile: _profile),
      PartnersScreen(currentProfile: _profile),
      PracticeScreen(currentProfile: _profile),
      PostsScreen(
        currentProfile: _profile,
        posts: _posts,
        isLoading: _isLoadingPosts,
        onRefresh: _loadPosts,
        onStateChange: () => setState(() {}),
      ),
      UserProfileScreen(
        profile: _profile,
        onUpdateProfile: _updateProfile,
        isDarkMode: w.isDarkMode,
        onToggleTheme: w.onToggleTheme,
        savedPosts: _posts.where((p) => (p as PostItem).isSaved).toList(),
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() {
          _currentIndex = index;
          if (index == 0) _unreadCount = 0;
        }),
        destinations: [
          NavigationDestination(
            icon: _unreadCount > 0 ? Badge(label: Text('$_unreadCount'), child: const Icon(Icons.chat_bubble_outline)) : const Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          const NavigationDestination(icon: Icon(Icons.people_outline), label: 'Partners'),
          const NavigationDestination(icon: Icon(Icons.videocam_outlined), label: 'Practice'),
          const NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Posts'),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
