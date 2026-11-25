import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<JsonMap>;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const ParleyApp());
}

final supabase = Supabase.instance.client;

class ParleyApp extends StatefulWidget {
  const ParleyApp({super.key});

  @override
  State<ParleyApp> createState() => _ParleyAppState();
}

class _ParleyAppState extends State<ParleyApp> {
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
          bodyLarge: TextStyle(color: _isDarkMode ? lightInk : inkBrown, height: 1.5),
          bodyMedium: TextStyle(color: _isDarkMode ? lightInk : inkBrown, height: 1.5),
        ),
        cardTheme: CardThemeData(
          color: _isDarkMode ? darkPaper : Colors.white,
          elevation: 2,
          shadowColor: _isDarkMode ? Colors.black45 : inkBrown.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isDarkMode ? lightInk.withValues(alpha: 0.1) : inkBrown.withValues(alpha: 0.1),
              width: 1,
            ),
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
    final user = supabase.auth.currentUser;
    if (user == null) {
      return WelcomeScreen(isDarkMode: isDarkMode, onToggleTheme: onToggleTheme);
    }
    return FutureBuilder<JsonMap?>(
      future: supabase.from('profiles').select().eq('id', user.id).maybeSingle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final profile = snapshot.data;
        if (profile == null) {
          return OnboardingScreen(isDarkMode: isDarkMode, onToggleTheme: onToggleTheme);
        }
        return MainScreen(
          userId: user.id,
          initialNative: profile['native_lang'] ?? 'English',
          initialLearning: profile['learning_lang'] ?? 'Spanish',
          initialName: profile['handle'] ?? '@reader',
          initialBio: profile['bio'] ?? '',
          initialAvatar: profile['avatar_url'],
          isDarkMode: isDarkMode,
          onToggleTheme: onToggleTheme,
        );
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const WelcomeScreen({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  void _showEmailAuthDialog({required bool isSignUp}) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    String errorText = '';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(isSignUp ? 'Create Account' : 'Sign In to Parley'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (min 6 characters)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();
                      if (email.isEmpty || password.length < 6) {
                        setModalState(() => errorText = 'Enter a valid email and 6+ char password.');
                        return;
                      }
                      setModalState(() {
                        isLoading = true;
                        errorText = '';
                      });
                      try {
                        if (isSignUp) {
                          await supabase.auth.signUp(email: email, password: password);
                        } else {
                          await supabase.auth.signInWithPassword(email: email, password: password);
                        }
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (mounted) {
                          Navigator.pushReplacement(
                            this.context,
                            MaterialPageRoute(
                              builder: (_) => AuthGate(
                                isDarkMode: widget.isDarkMode,
                                onToggleTheme: widget.onToggleTheme,
                              ),
                            ),
                          );
                        }
                      } on AuthException catch (e) {
                        setModalState(() {
                          errorText = e.message;
                          isLoading = false;
                        });
                      } catch (e) {
                        setModalState(() {
                          errorText = 'Connection error: $e';
                          isLoading = false;
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isSignUp ? 'Sign Up' : 'Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.auto_stories, size: 80, color: Theme.of(context).colorScheme.primary),
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
                  onPressed: () => _showEmailAuthDialog(isSignUp: true),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create New Account'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () => _showEmailAuthDialog(isSignUp: false),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In with Email'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
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
  const OnboardingScreen({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedNative;
  String? _selectedLearning;

  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _handleError = '';
  bool _isEnteringLibrary = false;

  static const List<String> _languages = [
    'Arabic', 'Bengali', 'Chinese (Mandarin)', 'Dutch', 'English', 'French',
    'German', 'Hindi', 'Indonesian', 'Italian', 'Japanese', 'Korean',
    'Persian', 'Polish', 'Portuguese', 'Punjabi', 'Russian', 'Spanish',
    'Swahili', 'Swedish', 'Turkish', 'Ukrainian', 'Urdu', 'Vietnamese'
  ];

  @override
  void dispose() {
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _checkAndCreateProfile() async {
    if (_isEnteringLibrary) return;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final rawHandle = _handleController.text.trim().toLowerCase().replaceAll('@', '');
    if (rawHandle.isEmpty) {
      setState(() => _handleError = 'Please enter a username.');
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
      _isEnteringLibrary = true;
      _handleError = '';
    });

    final fullHandle = '@$rawHandle';
    try {
      final existing = await supabase.from('profiles').select('id').eq('handle', fullHandle).maybeSingle();
      if (existing != null) {
        setState(() {
          _handleError = 'Username $fullHandle is already taken. Try another.';
          _isEnteringLibrary = false;
        });
        return;
      }

      await supabase.from('profiles').insert({
        'id': user.id,
        'handle': fullHandle,
        'native_lang': _selectedNative!,
        'learning_lang': _selectedLearning!,
        'bio': _bioController.text.trim(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            userId: user.id,
            initialNative: _selectedNative!,
            initialLearning: _selectedLearning!,
            initialName: fullHandle,
            initialBio: _bioController.text.trim(),
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _handleError = 'Could not save profile: $e';
        _isEnteringLibrary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Profile')),
      body: SingleChildScrollView(
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
              'Choose a unique username so your friends can find you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _handleController,
              decoration: InputDecoration(
                labelText: 'Unique Username',
                hintText: 'e.g. reader_99',
                prefixText: '@',
                errorText: _handleError.isNotEmpty ? _handleError : null,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedNative,
              decoration: InputDecoration(
                labelText: 'I speak (Native Language)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
              ),
              isExpanded: true,
              items: _languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
              onChanged: (val) => setState(() => _selectedNative = val),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedLearning,
              decoration: InputDecoration(
                labelText: 'I am learning (Target Language)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
              ),
              isExpanded: true,
              items: _languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
              onChanged: (val) => setState(() => _selectedLearning = val),
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
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isEnteringLibrary ? null : _checkAndCreateProfile,
                child: _isEnteringLibrary
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
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userId;
  final String initialNative;
  final String initialLearning;
  final String initialName;
  final String initialBio;
  final String? initialAvatar;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainScreen({
    super.key,
    required this.userId,
    required this.initialNative,
    required this.initialLearning,
    required this.initialName,
    required this.initialBio,
    this.initialAvatar,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late String _userName;
  late String _userBio;
  late String _nativeLanguage;
  late String _learningLanguage;
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _userName = widget.initialName;
    _userBio = widget.initialBio;
    _nativeLanguage = widget.initialNative;
    _learningLanguage = widget.initialLearning;
    _userAvatar = widget.initialAvatar;
  }

  Future<void> _saveUserData(String name, String native, String learning) async {
    setState(() {
      _userName = name;
      _nativeLanguage = native;
      _learningLanguage = learning;
    });
    await supabase.from('profiles').update({
      'handle': name,
      'native_lang': native,
      'learning_lang': learning,
    }).eq('id', widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MessagesScreen(currentUserId: widget.userId),
      PartnersScreen(currentUserId: widget.userId),
      const PracticeScreen(),
      PostsScreen(userId: widget.userId, userName: _userName),
      UserProfileScreen(
        userName: _userName,
        userBio: _userBio,
        nativeLang: _nativeLanguage,
        learningLang: _learningLanguage,
        userAvatar: _userAvatar,
        onUpdateProfile: _saveUserData,
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
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

class MessagesScreen extends StatelessWidget {
  final String currentUserId;
  const MessagesScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Correspondence')),
      body: FutureBuilder<JsonList>(
        future: supabase.from('profiles').select().neq('id', currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No other readers yet!\nHave your friend sign up with their email to start chatting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 16),
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final partner = users[index];
              final handle = partner['handle'] as String? ?? '@reader';
              final nativeLang = partner['native_lang'] as String? ?? '';
              final learningLang = partner['learning_lang'] as String? ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    handle.replaceFirst('@', '').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(handle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Speaks $nativeLang • Learning $learningLang'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      currentUserId: currentUserId,
                      partnerId: partner['id'] as String,
                      partnerHandle: handle,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String partnerId;
  final String partnerHandle;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.partnerId,
    required this.partnerHandle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _controller.clear();

    await supabase.from('messages').insert({
      'sender_id': widget.currentUserId,
      'receiver_id': widget.partnerId,
      'text': text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.partnerHandle)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<JsonList>(
              stream: supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allMessages = snapshot.data!;
                final conversation = allMessages.where((m) {
                  final s = m['sender_id'];
                  final r = m['receiver_id'];
                  return (s == widget.currentUserId && r == widget.partnerId) ||
                      (s == widget.partnerId && r == widget.currentUserId);
                }).toList();

                if (conversation.isEmpty) {
                  return Center(
                    child: Text(
                      'No letters yet.\nWrite your first message to ${widget.partnerHandle}!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: conversation.length,
                  itemBuilder: (context, index) {
                    final msg = conversation[index];
                    final isMe = msg['sender_id'] == widget.currentUserId;
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
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    );
                  },
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
                      hintText: 'Write a real message...',
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
  final String currentUserId;
  const PartnersScreen({super.key, required this.currentUserId});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fellow Readers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by @handle or language...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<JsonList>(
              future: supabase.from('profiles').select().neq('id', widget.currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allUsers = snapshot.data ?? [];
                final filtered = allUsers.where((u) {
                  final handle = (u['handle'] ?? '').toString().toLowerCase();
                  final native = (u['native_lang'] ?? '').toString().toLowerCase();
                  final learning = (u['learning_lang'] ?? '').toString().toLowerCase();
                  return _searchQuery.isEmpty ||
                      handle.contains(_searchQuery) ||
                      native.contains(_searchQuery) ||
                      learning.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching readers found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final partner = filtered[index];
                    final handle = partner['handle'] as String? ?? '@reader';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            handle.replaceFirst('@', '').substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(handle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Native: ${partner['native_lang']} • Learning: ${partner['learning_lang']}\n"${partner['bio']}"',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: Icon(Icons.chat, color: Theme.of(context).colorScheme.primary),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                currentUserId: widget.currentUserId,
                                partnerId: partner['id'] as String,
                                partnerHandle: handle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
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

class PostsScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const PostsScreen({super.key, required this.userId, required this.userName});

  void _showCreatePostSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Write a Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share a literary thought or language question...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final content = controller.text.trim();
                if (content.isNotEmpty) {
                  Navigator.pop(sheetContext);
                  await supabase.from('posts').insert({
                    'user_id': userId,
                    'author_handle': userName,
                    'content': content,
                  });
                }
              },
              child: const Text('Publish to the Feed'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Common Room')),
      body: StreamBuilder<JsonList>(
        stream: supabase.from('posts').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return const Center(child: Text('No posts yet. Be the first to write!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final author = post['author_handle'] as String? ?? '@reader';
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
                            child: Text(
                              author.replaceFirst('@', '').substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post['content'] ?? '',
                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostSheet(context),
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Write a Post', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.record_voice_over, size: 70, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              const Text(
                'Live Audio & Video Rooms',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Next up: we will wire real voice notes in Chat and live WebRTC/Agora calling here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).disabledColor, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  final String userName;
  final String userBio;
  final String nativeLang;
  final String learningLang;
  final String? userAvatar;
  final Future<void> Function(String, String, String) onUpdateProfile;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.userBio,
    required this.nativeLang,
    required this.learningLang,
    this.userAvatar,
    required this.onUpdateProfile,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                userName.replaceFirst('@', '').substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              userBio,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).disabledColor, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 25),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Native Language'),
                    trailing: Text(nativeLang, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Learning Language'),
                    trailing: Text(learningLang, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Night Reading Mode'),
              value: isDarkMode,
              onChanged: (_) => onToggleTheme(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WelcomeScreen(
                          isDarkMode: isDarkMode,
                          onToggleTheme: onToggleTheme,
                        ),
                      ),
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}