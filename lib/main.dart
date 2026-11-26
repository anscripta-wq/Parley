import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wofalpepdexhfzklqmdi.supabase.co',
    anonKey: 'sb_publishable_MDEwz1xdXjhx6Jr_Pu9s-Q_QrozJQF0',
  );

  runApp(const ParleyApp());
}

SupabaseClient get supabase => Supabase.instance.client;

class ParleyApp extends StatefulWidget {
  const ParleyApp({super.key});

  @override
  State createState() => _ParleyAppState();
}

class _ParleyAppState extends State {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

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
          titleTextStyle: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? lightInk : inkBrown,
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: _isDarkMode ? lightInk : inkBrown,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: _isDarkMode ? lightInk : inkBrown,
            height: 1.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: _isDarkMode ? darkPaper : Colors.white,
          elevation: 2,
          shadowColor: _isDarkMode
              ? Colors.black45
              : inkBrown.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isDarkMode
                  ? lightInk.withValues(alpha: 0.1)
                  : inkBrown.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDarkMode ? lightGreen : forestGreen,
            foregroundColor: _isDarkMode ? darkWood : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: AuthGate(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UserProfile {
  final String id;
  final String handle;
  final String nativeLang;
  final String learningLang;
  final String bio;
  final String? avatarUrl;
  final int streakCount;

  const UserProfile({
    required this.id,
    required this.handle,
    required this.nativeLang,
    required this.learningLang,
    required this.bio,
    this.avatarUrl,
    this.streakCount = 1,
  });

  factory UserProfile.fromMap(Map map) {
    final rawHandle = (map['handle'] ?? '').toString().trim();
    final formattedHandle = rawHandle.startsWith('@')
        ? rawHandle
        : '@$rawHandle';
    return UserProfile(
      id: map['id'].toString(),
      handle: formattedHandle,
      nativeLang: (map['native_lang'] ?? 'English').toString(),
      learningLang: (map['learning_lang'] ?? 'Spanish').toString(),
      bio: (map['bio'] ?? '').toString(),
      avatarUrl: map['avatar_url']?.toString(),
      streakCount: (map['streak_count'] as int?) ?? 1,
    );
  }
}

class PostItem {
  final String id;
  final String userId;
  final String authorHandle;
  final String content;
  int likesCount;
  bool isLiked;
  bool isSaved;
  final DateTime createdAt;

  PostItem({
    required this.id,
    required this.userId,
    required this.authorHandle,
    required this.content,
    required this.likesCount,
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
  });

  factory PostItem.fromMap(Map map) {
    final rawHandle = (map['author_handle'] ?? '@reader').toString().trim();
    final formattedHandle = rawHandle.startsWith('@')
        ? rawHandle
        : '@$rawHandle';
    return PostItem(
      id: map['id'].toString(),
      userId: (map['user_id'] ?? '').toString(),
      authorHandle: formattedHandle,
      content: (map['content'] ?? '').toString(),
      likesCount: (map['likes_count'] as int?) ?? 0,
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }

  String get initial {
    final clean = authorHandle.replaceFirst('@', '').trim();
    return clean.isEmpty ? 'P' : clean.substring(0, 1).toUpperCase();
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes == 0) return 'Just now';
    if (diff.inMinutes <= 59) return '${diff.inMinutes}m ago';
    if (diff.inHours <= 23) return '${diff.inHours}h ago';
    if (diff.inDays <= 6) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final bool isVoiceNote;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.isVoiceNote = false,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map map) {
    return ChatMessage(
      id: map['id'].toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      receiverId: (map['receiver_id'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      isVoiceNote: (map['is_voice_note'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }
}

const List kSupportedLanguages = [
  'Afrikaans', 'Albanian', 'Amharic', 'Arabic', 'Armenian', 'Azerbaijani',
  'Bengali', 'Bulgarian', 'Burmese', 'Catalan', 'Chinese (Mandarin)',
  'Croatian', 'Czech', 'Danish', 'Dutch', 'English', 'Estonian', 'Filipino',
  'Finnish', 'French', 'Georgian', 'German', 'Greek', 'Gujarati', 'Hebrew',
  'Hindi', 'Hungarian', 'Icelandic', 'Indonesian', 'Irish', 'Italian',
  'Japanese', 'Kannada', 'Kazakh', 'Khmer', 'Korean', 'Lao', 'Latvian',
  'Lithuanian', 'Macedonian', 'Malay', 'Malayalam', 'Maltese', 'Marathi',
  'Mongolian', 'Nepali', 'Norwegian', 'Persian', 'Polish', 'Portuguese',
  'Punjabi', 'Romanian', 'Russian', 'Serbian', 'Sinhala', 'Slovak',
  'Slovenian', 'Somali', 'Spanish', 'Swahili', 'Swedish', 'Tamil', 'Telugu',
  'Thai', 'Turkish', 'Ukrainian', 'Urdu', 'Uzbek', 'Vietnamese', 'Welsh', 'Zulu',
];

class AuthGate extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AuthGate({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State createState() => _AuthGateState();
}

class _AuthGateState extends State {
  @override
  Widget build(BuildContext context) {
    final w = widget as AuthGate;
    return StreamBuilder(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final data = snapshot.data as AuthState?;
        final session = data?.session ?? supabase.auth.currentSession;

        if (session == null) {
          return WelcomeScreen(
            isDarkMode: w.isDarkMode,
            onToggleTheme: w.onToggleTheme,
          );
        }

        return ProfileResolverScreen(
          key: ValueKey(session.user.id),
          userId: session.user.id,
          isDarkMode: w.isDarkMode,
          onToggleTheme: w.onToggleTheme,
        );
      },
    );
  }
}

class ProfileResolverScreen extends StatefulWidget {
  final String userId;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ProfileResolverScreen({
    super.key,
    required this.userId,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

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
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', w.userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  void _reloadProfile() {
    setState(() {
      _profileFuture = _fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as ProfileResolverScreen;
    return FutureBuilder(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('Opening your library...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 54, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load your profile:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _reloadProfile,
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () => supabase.auth.signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data as UserProfile?;
        if (profile == null) {
          return OnboardingScreen(
            isDarkMode: w.isDarkMode,
            onToggleTheme: w.onToggleTheme,
            onProfileCreated: _reloadProfile,
          );
        }

        return MainScreen(
          profile: profile,
          isDarkMode: w.isDarkMode,
          onToggleTheme: w.onToggleTheme,
        );
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const WelcomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State {
  bool _isSigningInWithGoogle = false;

  Future _signInWithGoogle() async {
    if (_isSigningInWithGoogle) return;
    setState(() => _isSigningInWithGoogle = true);

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? 'https://anscripta-wq.github.io/Parley/' : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningInWithGoogle = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Parley',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A sanctuary for language learners and literary minds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton.icon(
                    onPressed: _isSigningInWithGoogle ? null : _signInWithGoogle,
                    icon: _isSigningInWithGoogle
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata, size: 30),
                    label: Text(
                      _isSigningInWithGoogle
                          ? 'Connecting to Google...'
                          : 'Continue with Google',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailAuthScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.email),
                    label: const Text('Continue with Email'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length != 6 && password.length <= 5) {
      setState(() => _errorMessage = 'Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      if (_isLoginMode) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );
        if (response.session == null && mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage =
                'Account created! Please check your email inbox to confirm, then sign in.';
          });
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Authentication failed: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  Future _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Enter your email above first to reset password.');
      return;
    }
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? 'https://anscripta-wq.github.io/Parley/' : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not send reset email: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Sign In' : 'Create Account'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _isLoginMode ? 'Welcome Back' : 'Join Parley',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode
                      ? 'Sign in with your email and password.'
                      : 'Create an account to save your profile, posts, and chats.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                if (_isLoginMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  )
                else
                  const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isLoginMode ? 'Sign In' : 'Create Account'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                      _errorMessage = '';
                    });
                  },
                  child: Text(
                    _isLoginMode
                        ? "Don't have an account? Create one"
                        : 'Already have an account? Sign in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onProfileCreated;

  const OnboardingScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onProfileCreated,
  });

  @override
  State createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State {
  String? _selectedNative;
  String? _selectedLearning;
  String? _avatarUrl;

  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _handleError = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata;
      if (metadata != null && metadata['avatar_url'] != null) {
        _avatarUrl = metadata['avatar_url'].toString();
      }
      if (user.email != null && _handleController.text.isEmpty) {
        final suggested = user.email!
            .split('@')
            .first
            .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
            .toLowerCase();
        _handleController.text = suggested;
      }
    }
  }

  @override
  void dispose() {
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future _checkAndCreateProfile() async {
    if (_isSaving) return;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final rawHandle = _handleController.text
        .trim()
        .toLowerCase()
        .replaceFirst('@', '');

    if (rawHandle.isEmpty) {
      setState(() => _handleError = 'Please enter a username.');
      return;
    }

    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(rawHandle)) {
      setState(() => _handleError = 'Username must be 3-20 characters (letters, numbers, or _).');
      return;
    }

    if (_selectedNative == null || _selectedLearning == null) {
      setState(() => _handleError = 'Please select both languages.');
      return;
    }

    if (_selectedNative == _selectedLearning) {
      setState(() => _handleError = 'Native and Learning languages cannot be the same.');
      return;
    }

    if (_bioController.text.trim().isEmpty) {
      setState(() => _handleError = 'Please write a short bio about your goals.');
      return;
    }

    setState(() {
      _isSaving = true;
      _handleError = '';
    });

    try {
      final formattedHandle = '@$rawHandle';

      final existing = await supabase
          .from('profiles')
          .select('id')
          .or('handle.eq.$formattedHandle,handle.eq.$rawHandle')
          .maybeSingle();

      if (existing != null) {
        setState(() {
          _handleError = 'Username $formattedHandle is already taken. Try another.';
          _isSaving = false;
        });
        return;
      }

      await supabase.from('profiles').insert({
        'id': user.id,
        'handle': formattedHandle,
        'native_lang': _selectedNative,
        'learning_lang': _selectedLearning,
        'bio': _bioController.text.trim(),
        'avatar_url': _avatarUrl,
        'streak_count': 1,
      });

      if (mounted) {
        (widget as OnboardingScreen).onProfileCreated();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _handleError = e.code == '23505'
              ? 'Username @$rawHandle is already taken. Try another.'
              : 'Could not save profile: ${e.message}';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _handleError = 'Unexpected error: $e';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Profile'),
        actions: [
          TextButton(
            onPressed: () => supabase.auth.signOut(),
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join the Library',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose a unique username, set your languages, and tell us about yourself.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
                const SizedBox(height: 24),
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                        ? Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _handleController,
                  decoration: InputDecoration(
                    labelText: 'Unique Username',
                    hintText: 'e.g. reader_99',
                    prefixText: '@',
                    errorText: _handleError.isNotEmpty ? _handleError : null,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.alternate_email, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField(
                  initialValue: _selectedNative,
                  decoration: InputDecoration(
                    labelText: 'I speak (Native Language)',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                  ),
                  isExpanded: true,
                  items: kSupportedLanguages
                      .map((lang) => DropdownMenuItem(value: lang, child: Text(lang, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedNative = val as String?),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField(
                  initialValue: _selectedLearning,
                  decoration: InputDecoration(
                    labelText: 'I am learning (Target Language)',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                  ),
                  isExpanded: true,
                  items: kSupportedLanguages
                      .map((lang) => DropdownMenuItem(value: lang, child: Text(lang, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLearning = val as String?),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Short Bio',
                    hintText: 'Why are you learning? What do you like to read?',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _checkAndCreateProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Enter the Library'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final UserProfile profile;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainScreen({
    super.key,
    required this.profile,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State createState() => _MainScreenState();
}

class _MainScreenState extends State {
  int _currentIndex = 0;
  late UserProfile _profile;
  List _posts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _profile = (widget as MainScreen).profile;
    _loadPosts();
  }

  Future _loadPosts() async {
    try {
      final rows = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        final savedIds = _posts.where((p) => p.isSaved).map((p) => p.id).toSet();
        final likedIds = _posts.where((p) => p.isLiked).map((p) => p.id).toSet();

        setState(() {
          _posts = (rows as List).map((row) {
            final item = PostItem.fromMap(row as Map);
            item.isSaved = savedIds.contains(item.id);
            item.isLiked = likedIds.contains(item.id);
            return item;
          }).toList();
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  Future _updateProfile({
    required String handle,
    required String nativeLang,
    required String learningLang,
    required String bio,
  }) async {
    final clean = handle.trim().toLowerCase().replaceFirst('@', '');
    final formatted = '@$clean';

    await supabase.from('profiles').update({
      'handle': formatted,
      'native_lang': nativeLang,
      'learning_lang': learningLang,
      'bio': bio,
    }).eq('id', _profile.id);

    if (mounted) {
      setState(() {
        _profile = UserProfile(
          id: _profile.id,
          handle: formatted,
          nativeLang: nativeLang,
          learningLang: learningLang,
          bio: bio,
          avatarUrl: _profile.avatarUrl,
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
      const PracticeScreen(),
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
        savedPosts: _posts.where((p) => p.isSaved).toList(),
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Partners'),
          NavigationDestination(icon: Icon(Icons.videocam_outlined), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Posts'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

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
              onChanged: (value) =>
                  setState(() => _postSearchQuery = value.trim().toLowerCase()),
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
                              Center(
                                child: Text('No posts yet. Be the first to share a thought!'),
                              ),
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

class MessagesScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const MessagesScreen({super.key, required this.currentProfile});

  @override
  State createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State {
  String _searchQuery = '';
  bool _isLoading = true;
  List _threads = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future _loadConversations() async {
    final w = widget as MessagesScreen;
    try {
      final myId = w.currentProfile.id;
      final msgs = await supabase
          .from('messages')
          .select()
          .or('sender_id.eq.$myId,receiver_id.eq.$myId')
          .order('created_at', ascending: false);

      final latestByPartner = {};
      for (final raw in (msgs as List)) {
        final msg = raw as Map;
        final partnerId = msg['sender_id'] == myId
            ? msg['receiver_id'].toString()
            : msg['sender_id'].toString();
        latestByPartner.putIfAbsent(partnerId, () => msg);
      }

      if (latestByPartner.isEmpty) {
        if (mounted) {
          setState(() {
            _threads = [];
            _isLoading = false;
          });
        }
        return;
      }

      final profilesRows = await supabase
          .from('profiles')
          .select()
          .inFilter('id', latestByPartner.keys.map((k) => k.toString()).toList());

      final profilesMap = {};
      for (final p in (profilesRows as List)) {
        final up = UserProfile.fromMap(p as Map);
        profilesMap[up.id] = up;
      }

      final built = [];
      for (final entry in latestByPartner.entries) {
        final partner = profilesMap[entry.key];
        if (partner != null) {
          built.add({
            'partner': partner,
            'lastMessage': (entry.value['text'] ?? '').toString(),
          });
        }
      }

      if (mounted) {
        setState(() {
          _threads = built;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as MessagesScreen;
    final filtered = _threads.where((t) {
      final partner = t['partner'] as UserProfile;
      return _searchQuery.isEmpty ||
          partner.handle.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Correspondence'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadConversations),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search letters...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No conversations yet.\nGo to the Partners tab to message a fellow reader.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final partner = filtered[index]['partner'] as UserProfile;
                      final lastMessage = filtered[index]['lastMessage'] as String;
                      final initial = partner.handle.replaceFirst('@', '').substring(0, 1).toUpperCase();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(initial, style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(partner.handle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                currentProfile: w.currentProfile,
                                partner: partner,
                              ),
                            ),
                          );
                          _loadConversations();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final UserProfile currentProfile;
  final UserProfile partner;

  const ChatScreen({
    super.key,
    required this.currentProfile,
    required this.partner,
  });

  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future _loadMessages() async {
    final w = widget as ChatScreen;
    final myId = w.currentProfile.id;
    final otherId = w.partner.id;

    try {
      final rows = await supabase
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$myId,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$myId)',
          )
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = (rows as List).map((r) => ChatMessage.fromMap(r as Map)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future _sendMessage() async {
    final w = widget as ChatScreen;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    HapticFeedback.lightImpact();

    try {
      await supabase.from('messages').insert({
        'sender_id': w.currentProfile.id,
        'receiver_id': w.partner.id,
        'text': text,
        'is_voice_note': false,
      });
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as ChatScreen;
    return Scaffold(
      appBar: AppBar(
        title: Text(w.partner.handle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.\nWrite your first letter to ${w.partner.handle}!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index] as ChatMessage;
                      final isMe = msg.senderId == w.currentProfile.id;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            ),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 15,
                            ),
                          ),
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
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF3E2F2F),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PartnersScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const PartnersScreen({super.key, required this.currentProfile});

  @override
  State createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State {
  String _searchQuery = '';
  bool _isLoading = true;
  List _partners = [];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future _loadPartners() async {
    final w = widget as PartnersScreen;
    try {
      final rows = await supabase
          .from('profiles')
          .select()
          .neq('id', w.currentProfile.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _partners = (rows as List).map((r) => UserProfile.fromMap(r as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as PartnersScreen;
    final filtered = _partners.where((p) {
      final partner = p as UserProfile;
      return _searchQuery.isEmpty ||
          partner.handle.toLowerCase().contains(_searchQuery) ||
          partner.nativeLang.toLowerCase().contains(_searchQuery) ||
          partner.learningLang.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fellow Readers'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPartners),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by @handle or language...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      'No other readers found yet.',
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final partner = filtered[index] as UserProfile;
                      final initial = partner.handle.replaceFirst('@', '').substring(0, 1).toUpperCase();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(initial, style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(partner.handle, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Speaks ${partner.nativeLang} • Learning ${partner.learningLang}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PartnerDetailScreen(
                                  currentProfile: w.currentProfile,
                                  partner: partner,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class PartnerDetailScreen extends StatelessWidget {
  final UserProfile currentProfile;
  final UserProfile partner;

  const PartnerDetailScreen({
    super.key,
    required this.currentProfile,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
    final initial = partner.handle.replaceFirst('@', '').substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(partner.handle)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(initial, style: const TextStyle(fontSize: 36, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            Text(partner.handle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                Chip(label: Text('Native: ${partner.nativeLang}')),
                Chip(label: Text('Learning: ${partner.learningLang}')),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('About Me', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                partner.bio.isEmpty ? 'No bio provided yet.' : partner.bio,
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: Text('Message ${partner.handle}'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        currentProfile: currentProfile,
                        partner: partner,
                      ),
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
}

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spoken Practice')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.record_voice_over, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text('Live Spoken Practice', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'This is a respectful language-learning space. Live audio/video rooms are coming soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final w = widget as UserProfileScreen;
    final initial = w.profile.handle.replaceFirst('@', '').substring(0, 1).toUpperCase();

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
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: (w.profile.avatarUrl != null && w.profile.avatarUrl!.isNotEmpty)
                  ? NetworkImage(w.profile.avatarUrl!)
                  : null,
              child: (w.profile.avatarUrl == null || w.profile.avatarUrl!.isEmpty)
                  ? Text(initial, style: const TextStyle(fontSize: 38, color: Colors.white))
                  : null,
            ),
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
            const SizedBox(height: 20),
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
