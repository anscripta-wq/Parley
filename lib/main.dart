import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ParleyApp());
}

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
          shadowColor: _isDarkMode ? Colors.black45 : inkBrown.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isDarkMode
                  ? lightInk.withOpacity(0.1)
                  : inkBrown.withOpacity(0.1),
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
      home: WelcomeScreen(isDarkMode: _isDarkMode, onToggleTheme: _toggleTheme),
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ---------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------
class PostItem {
  final String name;
  final String time;
  final String content;
  final String initial;
  final String color;
  int likes;
  bool isLiked;
  bool isSaved;
  final List comments;
  final String avatarUrl;

  PostItem({
    required this.name,
    required this.time,
    required this.content,
    required this.initial,
    required this.color,
    required this.likes,
    required this.isLiked,
    this.isSaved = false,
    required this.comments,
    this.avatarUrl = '',
  });
}

class ChatMessage {
  final String text;
  final bool isMe;
  final String translation;
  bool showTranslation;
  final String grammarCorrection;
  bool showCorrection;
  final bool isVoiceNote;
  final String duration;
  final DateTime sentAt;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.translation,
    this.showTranslation = false,
    this.grammarCorrection = '',
    this.showCorrection = false,
    this.isVoiceNote = false,
    this.duration = '0:08',
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();
}

class Partner {
  final String name;
  final String flag;
  final String nativeLang;
  final String learningLang;
  final String bio;
  final String handle;

  const Partner({
    required this.name,
    required this.flag,
    required this.nativeLang,
    required this.learningLang,
    required this.bio,
    required this.handle,
  });
}

// ---------------------------------------------------------
// WELCOME SCREEN
// ---------------------------------------------------------
class WelcomeScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const WelcomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OnboardingScreen(
                          isDarkMode: isDarkMode,
                          onToggleTheme: onToggleTheme,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 30),
                  label: const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).cardColor,
                    foregroundColor: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color,
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
                        builder: (context) => OnboardingScreen(
                          isDarkMode: isDarkMode,
                          onToggleTheme: onToggleTheme,
                        ),
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
    );
  }
}

// ---------------------------------------------------------
// ONBOARDING SCREEN
// ---------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  const OnboardingScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State {
  String? _selectedNative;
  String? _selectedLearning;
  String? _pickedImageUrl;

  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _handleError = '';
  bool _isEnteringLibrary = false;

  final List _languages = [
    'Afrikaans',
    'Albanian',
    'Amharic',
    'Arabic',
    'Armenian',
    'Azerbaijani',
    'Bengali',
    'Bulgarian',
    'Burmese',
    'Catalan',
    'Chinese (Mandarin)',
    'Croatian',
    'Czech',
    'Danish',
    'Dutch',
    'English',
    'Estonian',
    'Filipino',
    'Finnish',
    'French',
    'Georgian',
    'German',
    'Greek',
    'Gujarati',
    'Hebrew',
    'Hindi',
    'Hungarian',
    'Icelandic',
    'Indonesian',
    'Irish',
    'Italian',
    'Japanese',
    'Kannada',
    'Kazakh',
    'Khmer',
    'Korean',
    'Lao',
    'Latvian',
    'Lithuanian',
    'Macedonian',
    'Malay',
    'Malayalam',
    'Maltese',
    'Marathi',
    'Mongolian',
    'Nepali',
    'Norwegian',
    'Persian',
    'Polish',
    'Portuguese',
    'Punjabi',
    'Romanian',
    'Russian',
    'Serbian',
    'Sinhala',
    'Slovak',
    'Slovenian',
    'Somali',
    'Spanish',
    'Swahili',
    'Swedish',
    'Tamil',
    'Telugu',
    'Thai',
    'Turkish',
    'Ukrainian',
    'Urdu',
    'Uzbek',
    'Vietnamese',
    'Welsh',
    'Zulu',
  ];

  final List _takenUsernames = [
    'ahmed',
    'maria',
    'john',
    'sara',
    'admin',
    'parley',
  ];

  void _pickImage() {
    setState(() {
      _pickedImageUrl =
          'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200/200';
    });
  }

  @override
  void dispose() {
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _checkAndCreateProfile() async {
    if (_isEnteringLibrary) return;
    setState(() => _isEnteringLibrary = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final w = widget as OnboardingScreen;
    String handle = _handleController.text.trim().toLowerCase();

    if (handle.isEmpty) {
      setState(() {
        _handleError = 'Please enter a username.';
        _isEnteringLibrary = false;
      });
      return;
    }

    if (_takenUsernames.contains(handle)) {
      setState(() {
        _handleError = 'Username @$handle is already taken. Try another.';
        _isEnteringLibrary = false;
      });
      return;
    }

    if (_selectedNative == null || _selectedLearning == null) {
      setState(() {
        _handleError = 'Please select both languages.';
        _isEnteringLibrary = false;
      });
      return;
    }

    if (_selectedNative == _selectedLearning) {
      setState(() {
        _handleError = 'Native and Learning languages cannot be the same.';
        _isEnteringLibrary = false;
      });
      return;
    }

    if (_bioController.text.trim().isEmpty) {
      setState(() {
        _handleError = 'Please write a short bio about your goals.';
        _isEnteringLibrary = false;
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialNative: _selectedNative!,
          initialLearning: _selectedLearning!,
          initialName: '@$handle',
          initialBio: _bioController.text.trim(),
          initialAvatar: _pickedImageUrl,
          isDarkMode: w.isDarkMode,
          onToggleTheme: w.onToggleTheme,
        ),
      ),
    );
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
              'Choose a unique username, set your languages, and tell us about yourself.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                      backgroundImage: _pickedImageUrl != null
                          ? NetworkImage(_pickedImageUrl!)
                          : null,
                      child: _pickedImageUrl == null
                          ? Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    if (_pickedImageUrl != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _handleController,
              decoration: InputDecoration(
                labelText: 'Unique Username',
                hintText: 'e.g. reader_99',
                prefixText: '@',
                errorText: _handleError.isNotEmpty ? _handleError : null,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              value: _selectedNative,
              decoration: InputDecoration(
                labelText: 'I speak (Native Language)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              isExpanded: true,
              items: _languages
                  .map(
                    (lang) => DropdownMenuItem(
                      value: lang as String,
                      child: Text(lang, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedNative = val as String?),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              value: _selectedLearning,
              decoration: InputDecoration(
                labelText: 'I am learning (Target Language)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              isExpanded: true,
              items: _languages
                  .map(
                    (lang) => DropdownMenuItem(
                      value: lang as String,
                      child: Text(lang, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedLearning = val as String?),
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
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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

// ---------------------------------------------------------
// MAIN SCREEN
// ---------------------------------------------------------
class MainScreen extends StatefulWidget {
  final String initialNative;
  final String initialLearning;
  final String initialName;
  final String initialBio;
  final String? initialAvatar;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainScreen({
    super.key,
    required this.initialNative,
    required this.initialLearning,
    required this.initialName,
    required this.initialBio,
    this.initialAvatar,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State createState() => _MainScreenState();
}

class _MainScreenState extends State {
  int _currentIndex = 0;
  String _userName = '';
  String _userBio = '';
  String _nativeLanguage = '';
  String _learningLanguage = '';
  String? _userAvatar;

  final List<PostItem> _globalPosts = [
    PostItem(
      name: '@sara_m',
      time: '2 hours ago',
      content:
          'What is the best way to remember new vocabulary? I keep forgetting the words after a few days. Any tips?',
      initial: 'S',
      color: 'orange',
      likes: 5,
      isLiked: false,
      isSaved: false,
      comments: ['I use flashcards!', 'Try reading books in that language.'],
    ),
    PostItem(
      name: '@david_reads',
      time: '1 day ago',
      content:
          'Today I learned 10 new words in Japanese! こんにちは (Hello), ありがとう (Thank you). Who else is learning Japanese?',
      initial: 'D',
      color: 'teal',
      likes: 12,
      isLiked: true,
      isSaved: false,
      comments: ['Wow, great job!'],
    ),
  ];

  int _unreadNotifications = 2;
  bool _showIncomingCall = false;

  @override
  void initState() {
    super.initState();
    final w = widget as MainScreen;
    _userName = w.initialName;
    _userBio = w.initialBio;
    _nativeLanguage = w.initialNative;
    _learningLanguage = w.initialLearning;
    _userAvatar = w.initialAvatar;

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_showIncomingCall) {
        setState(() {
          _showIncomingCall = true;
        });
      }
    });
  }

  void _saveUserData(String name, String native, String learning) {
    setState(() {
      _userName = name;
      _nativeLanguage = native;
      _learningLanguage = learning;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as MainScreen;
    final List screens = [
      MessagesScreen(
        userName: _userName,
        nativeLang: _nativeLanguage,
        learningLang: _learningLanguage,
        onUpdateProfile: _saveUserData,
        unreadCount: _unreadNotifications,
        onClearNotifications: () => setState(() => _unreadNotifications = 0),
        isDarkMode: w.isDarkMode,
        onToggleTheme: w.onToggleTheme,
      ),
      const PartnersScreen(),
      const PracticeScreen(),
      PostsScreen(
        userName: _userName,
        userAvatar: _userAvatar,
        globalPosts: _globalPosts,
        onStateChange: () => setState(() {}),
      ),
      UserProfileScreen(
        userName: _userName,
        userBio: _userBio,
        nativeLang: _nativeLanguage,
        learningLang: _learningLanguage,
        userAvatar: _userAvatar,
        onUpdateProfile: _saveUserData,
        onUpdateAvatar: (avatar) => setState(() => _userAvatar = avatar),
        isDarkMode: w.isDarkMode,
        onToggleTheme: w.onToggleTheme,
        globalPosts: _globalPosts,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: screens[_currentIndex] as Widget),
          if (_showIncomingCall)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(15),
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.videocam, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Incoming Video Call',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Kenji 🇯🇵 wants to practice',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call_end, color: Colors.red),
                        onPressed: () =>
                            setState(() => _showIncomingCall = false),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.videocam,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() => _showIncomingCall = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VideoCallScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text('$_unreadNotifications'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Partners',
          ),
          const NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            label: 'Practice',
          ),
          const NavigationDestination(
            icon: Icon(Icons.article_outlined),
            label: 'Posts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// POSTS SCREEN
// ---------------------------------------------------------
class PostsScreen extends StatefulWidget {
  final String userName;
  final String? userAvatar;
  final List<PostItem> globalPosts;
  final VoidCallback onStateChange;

  const PostsScreen({
    super.key,
    required this.userName,
    this.userAvatar,
    required this.globalPosts,
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

  void _createPost(String text) {
    final w = widget as PostsScreen;
    if (text.trim().isNotEmpty) {
      setState(() {
        w.globalPosts.insert(
          0,
          PostItem(
            name: w.userName,
            time: 'Just now',
            content: text.trim(),
            initial: w.userName
                .replaceFirst('@', '')
                .substring(0, 1)
                .toUpperCase(),
            color: 'blue',
            likes: 0,
            isLiked: false,
            isSaved: false,
            comments: [],
            avatarUrl: w.userAvatar ?? '',
          ),
        );
      });
      w.onStateChange();
    }
  }

  void _toggleLike(int index) {
    final w = widget as PostsScreen;
    setState(() {
      final post = w.globalPosts[index];
      post.isLiked = !post.isLiked;
      if (post.isLiked) {
        post.likes++;
      } else {
        post.likes--;
      }
    });
    w.onStateChange();
  }

  void _toggleSave(int index) {
    final w = widget as PostsScreen;
    setState(() {
      w.globalPosts[index].isSaved = !w.globalPosts[index].isSaved;
    });
    w.onStateChange();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          w.globalPosts[index].isSaved
              ? 'Saved to your readings.'
              : 'Removed from saved.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showCommentSheet(int postIndex) {
    final w = widget as PostsScreen;
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => Padding(
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
            const Text(
              'Join the Discussion',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts, debate politely...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.trim().isNotEmpty) {
                  setState(() {
                    w.globalPosts[postIndex].comments.add(
                      commentController.text.trim(),
                    );
                  });
                  w.onStateChange();
                  Navigator.pop(context);
                }
              },
              child: const Text('Post Reply'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as PostsScreen;
    return Scaffold(
      appBar: AppBar(title: const Text('The Common Room')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
            child: Builder(
              builder: (context) {
                final filteredPosts = w.globalPosts
                    .where(
                      (post) =>
                          _postSearchQuery.isEmpty ||
                          post.content.toLowerCase().contains(
                            _postSearchQuery,
                          ) ||
                          post.name.toLowerCase().contains(_postSearchQuery) ||
                          post.comments.any(
                            (comment) => comment
                                .toString()
                                .toLowerCase()
                                .contains(_postSearchQuery),
                          ),
                    )
                    .toList();
                if (filteredPosts.isEmpty) {
                  return const Center(
                    child: Text('No discussions match your search.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
                    final postIndex = w.globalPosts.indexOf(post);
                    final Color avatarColor = post.color == 'orange'
                        ? Colors.orange
                        : (post.color == 'teal'
                              ? Colors.teal
                              : Theme.of(context).colorScheme.primary);

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
                                  backgroundColor: avatarColor,
                                  backgroundImage: post.avatarUrl.isNotEmpty
                                      ? NetworkImage(post.avatarUrl)
                                      : null,
                                  child: post.avatarUrl.isEmpty
                                      ? Text(
                                          post.initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        post.time,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).disabledColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    post.isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: post.isSaved
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _toggleSave(postIndex),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              post.content,
                              style: const TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _toggleLike(postIndex),
                                  icon: Icon(
                                    post.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 20,
                                    color: post.isLiked
                                        ? Colors.red
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                  ),
                                  label: Text(
                                    post.likes > 0
                                        ? '${post.likes} Appreciations'
                                        : 'Appreciate',
                                    style: TextStyle(
                                      color: post.isLiked
                                          ? Colors.red
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showCommentSheet(postIndex),
                                  icon: Icon(
                                    Icons.comment,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                  label: Text(
                                    post.comments.isNotEmpty
                                        ? '${post.comments.length} Replies'
                                        : 'Reply',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (post.comments.isNotEmpty) ...[
                              const Divider(),
                              ...post.comments.map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.format_quote,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          c.toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
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
        label: const Text(
          'Write a Post',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3E2F2F),
      ),
    );
  }
}

// ---------------------------------------------------------
// MESSAGES LIST SCREEN
// ---------------------------------------------------------
class MessagesScreen extends StatelessWidget {
  final String userName;
  final String nativeLang;
  final String learningLang;
  final Function(String, String, String) onUpdateProfile;
  final int unreadCount;
  final VoidCallback onClearNotifications;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MessagesScreen({
    super.key,
    required this.userName,
    required this.nativeLang,
    required this.learningLang,
    required this.onUpdateProfile,
    required this.unreadCount,
    required this.onClearNotifications,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  Widget _buildAvatar(String initial, Color color, bool isOnline) {
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: color,
          child: Text(initial, style: const TextStyle(color: Colors.white)),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correspondence'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  onClearNotifications();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
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
            child: ListView(
              children: [
                ListTile(
                  leading: _buildAvatar(
                    'A',
                    Theme.of(context).colorScheme.primary,
                    true,
                  ),
                  title: const Text(
                    '@ahmed_t',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Merhaba! How do you say "Hello" in Urdu?',
                  ),
                  trailing: Text(
                    '10:45 AM',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ChatScreen(name: '@ahmed_t', flag: '🇹🇷'),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _buildAvatar('M', const Color(0xFF3E2F2F), false),
                  title: const Text(
                    '@maria_es',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'That sounds great! Let\'s practice tomorrow.',
                  ),
                  trailing: Text(
                    'Yesterday',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ChatScreen(name: '@maria_es', flag: '🇪🇸'),
                    ),
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

// ---------------------------------------------------------
// CHAT SCREEN
// ---------------------------------------------------------
class ChatScreen extends StatefulWidget {
  final String name;
  final String flag;
  const ChatScreen({super.key, required this.name, required this.flag});

  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _isSearching = false;
  bool _isTyping = false;
  bool _grammarModeOn = false;
  String _searchQuery = '';

  final List _messages = [
    ChatMessage(
      text: "Merhaba! How do you say 'Hello' in Urdu?",
      isMe: false,
      translation: "Hello! How do you say 'Hello' in Urdu?",
      grammarCorrection: "Hello! How do you say 'Hello' in Urdu?",
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ChatMessage(
      text: "It is 'Assalam o Alaikum'!",
      isMe: true,
      translation: "",
    ),
    ChatMessage(
      text: "I goes to school yesterday.",
      isMe: false,
      translation: "I went to school yesterday.",
      grammarCorrection: "I went to school yesterday.",
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendVoiceNote() {
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Voice message',
          isMe: true,
          translation: '',
          isVoiceNote: true,
          duration: '0:08',
        ),
      );
      _isTyping = false;
    });
    _scrollChatToBottom();
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _messages.add(
          ChatMessage(
            text: _controller.text.trim(),
            isMe: true,
            translation: "",
          ),
        );
        _controller.clear();
        _isTyping = false;
      });
      _scrollChatToBottom();
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat history cleared.')));
  }

  void _toggleTranslation(int index) {
    setState(() {
      final msg = _messages[index] as ChatMessage;
      msg.showTranslation = !msg.showTranslation;
    });
  }

  void _toggleCorrection(int index) {
    setState(() {
      final msg = _messages[index] as ChatMessage;
      msg.showCorrection = !msg.showCorrection;
    });
  }

  void _showSafetyMenu() {
    final w = widget as ChatScreen;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.spellcheck, color: Colors.green),
                title: const Text('Auto-Correct Grammar'),
                subtitle: const Text('See corrections for messages'),
                value: _grammarModeOn,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  setModalState(() => _grammarModeOn = val);
                  setState(() => _grammarModeOn = val);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.orange),
                title: const Text('Clear Chat History'),
                onTap: () {
                  Navigator.pop(context);
                  _clearChat();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportScreen(reportedUser: w.name),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block User'),
                onTap: () async {
                  Navigator.pop(context);
                  final shouldBlock = await showDialog<bool>(
                    context: this.context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Block this user?'),
                      content: Text(
                        'You will no longer receive messages from ${w.name}. This is a mock action in the prototype.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text(
                            'Block',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (shouldBlock == true && mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('${w.name} has been blocked (mock).'),
                      ),
                    );
                    Navigator.pop(this.context);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as ChatScreen;
    final displayedMessages = _isSearching && _searchQuery.isNotEmpty
        ? _messages
              .where(
                (msg) => (msg as ChatMessage).text.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList()
        : _messages;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search in chat...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Row(
                children: [
                  Text(w.flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(w.name, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showSafetyMenu,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: displayedMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isSearching
                              ? 'No messages found.'
                              : 'No messages yet.\nSay hello!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).disabledColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedMessages.length,
                    itemBuilder: (context, index) {
                      final msg = displayedMessages[index] as ChatMessage;
                      final String textToShow =
                          msg.showCorrection && msg.grammarCorrection.isNotEmpty
                          ? msg.grammarCorrection
                          : (msg.showTranslation ? msg.translation : msg.text);
                      final int originalIndex = _messages.indexOf(msg);

                      final day = DateTime(
                        msg.sentAt.year,
                        msg.sentAt.month,
                        msg.sentAt.day,
                      );
                      final today = DateTime.now();
                      final todayDate = DateTime(
                        today.year,
                        today.month,
                        today.day,
                      );
                      final yesterdayDate = todayDate.subtract(
                        const Duration(days: 1),
                      );
                      final dateLabel = day == todayDate
                          ? 'Today'
                          : (day == yesterdayDate
                                ? 'Yesterday'
                                : '${msg.sentAt.day}/${msg.sentAt.month}/${msg.sentAt.year}');
                      final previousMessage = index > 0
                          ? displayedMessages[index - 1] as ChatMessage
                          : null;
                      final previousDay = previousMessage == null
                          ? null
                          : DateTime(
                              previousMessage.sentAt.year,
                              previousMessage.sentAt.month,
                              previousMessage.sentAt.day,
                            );
                      final showDateDivider = previousDay != day;
                      return Column(
                        crossAxisAlignment: msg.isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (showDateDivider)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    dateLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (msg.isVoiceNote)
                            Align(
                              alignment: msg.isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: _VoiceNoteBubble(
                                duration: msg.duration,
                                isMe: msg.isMe,
                              ),
                            )
                          else
                            Align(
                              alignment: msg.isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: msg.isMe
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16)
                                      .copyWith(
                                        bottomRight: msg.isMe
                                            ? Radius.zero
                                            : const Radius.circular(16),
                                        bottomLeft: msg.isMe
                                            ? const Radius.circular(16)
                                            : Radius.zero,
                                      ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  textToShow,
                                  style: TextStyle(
                                    color: msg.isMe
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          if (!msg.isMe)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                bottom: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () =>
                                        _toggleTranslation(originalIndex),
                                    child: Row(
                                      children: [
                                        Icon(
                                          msg.showTranslation
                                              ? Icons.undo
                                              : Icons.translate,
                                          size: 16,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          msg.showTranslation
                                              ? 'Original'
                                              : 'Translate',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_grammarModeOn) ...[
                                    const SizedBox(width: 16),
                                    InkWell(
                                      onTap: () =>
                                          _toggleCorrection(originalIndex),
                                      child: Row(
                                        children: [
                                          Icon(
                                            msg.showCorrection
                                                ? Icons.undo
                                                : Icons.spellcheck,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            msg.showCorrection
                                                ? 'Original'
                                                : 'Grammar Check',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
              child: Row(
                children: [
                  Text(
                    '${w.name} is typing...',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Send a voice note (mock)',
                    icon: Icon(
                      Icons.mic_none,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _sendVoiceNote,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (text) {
                        setState(() {
                          _isTyping = text.isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF3E2F2F),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
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

// ---------------------------------------------------------
// NOTIFICATIONS SCREEN
// ---------------------------------------------------------
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.chat, color: Colors.white, size: 20),
            ),
            title: const Text('New letter from @ahmed_t'),
            subtitle: const Text('Merhaba! How do you say Hello in Urdu?'),
            trailing: Text(
              '5m ago',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF3E2F2F),
              child: Icon(Icons.videocam, color: Colors.white, size: 20),
            ),
            title: const Text('Video practice matched'),
            subtitle: const Text('Kenji is waiting for you.'),
            trailing: Text(
              '1h ago',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// SAFETY / REPORT SCREEN
// ---------------------------------------------------------
class ReportScreen extends StatefulWidget {
  final String reportedUser;
  const ReportScreen({super.key, required this.reportedUser});

  @override
  State createState() => _ReportScreenState();
}

class _ReportScreenState extends State {
  String? _selectedReason;
  final List _reasons = [
    'Inappropriate content (Nudity, etc.)',
    'Dating or Flirting (Not allowed here)',
    'Hate speech or Racism',
    'Religious or Political arguments',
    'Spamming or Advertising',
  ];

  @override
  Widget build(BuildContext context) {
    final w = widget as ReportScreen;
    return Scaffold(
      appBar: AppBar(title: const Text('Report User')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why are you reporting ${w.reportedUser}?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Your report is anonymous. We will review it quickly.',
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _reasons.length,
                itemBuilder: (context, index) {
                  final String reason = _reasons[index].toString();
                  return RadioListTile(
                    title: Text(reason),
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (val) =>
                        setState(() => _selectedReason = val as String?),
                    activeColor: Colors.red,
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedReason == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'User reported. Thank you for keeping Parley safe.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// USER PROFILE SCREEN (Now with Daily Streak!)
// ---------------------------------------------------------
class UserProfileScreen extends StatefulWidget {
  final String userName;
  final String userBio;
  final String nativeLang;
  final String learningLang;
  final String? userAvatar;
  final Function(String, String, String) onUpdateProfile;
  final ValueChanged<String?> onUpdateAvatar;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final List<PostItem> globalPosts;

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.userBio,
    required this.nativeLang,
    required this.learningLang,
    this.userAvatar,
    required this.onUpdateProfile,
    required this.onUpdateAvatar,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.globalPosts,
  });

  @override
  State createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State {
  late TextEditingController _nameController;
  late String _currentNative;
  late String _currentLearning;
  String? _localAvatar;

  void _pickProfileAvatar() {
    setState(() {
      _localAvatar =
          'https://picsum.photos/seed/parley-${DateTime.now().millisecondsSinceEpoch}/300/300';
    });
    (widget as UserProfileScreen).onUpdateAvatar(_localAvatar);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture updated (mock).')),
    );
  }

  @override
  void initState() {
    super.initState();
    final w = widget as UserProfileScreen;
    _nameController = TextEditingController(text: w.userName);
    _currentNative = w.nativeLang;
    _currentLearning = w.learningLang;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as UserProfileScreen;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _pickProfileAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: (_localAvatar ?? w.userAvatar) != null
                        ? NetworkImage(_localAvatar ?? w.userAvatar!)
                        : null,
                    child: (_localAvatar ?? w.userAvatar) == null
                        ? const Text(
                            'Y',
                            style: TextStyle(fontSize: 40, color: Colors.white),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.edit, size: 20, color: Colors.grey),
                ),
                onSubmitted: (value) {
                  w.onUpdateProfile(value, _currentNative, _currentLearning);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                w.userBio,
                style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pakistan 🇵🇰',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // DAILY STREAK WIDGET
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.red.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '5-Day Streak!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Keep practicing daily to reach 10 days.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
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
                      leading: Icon(
                        Icons.flag,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Native Language'),
                      trailing: Text(
                        _currentNative,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LanguageSetupScreen(
                              currentNative: _currentNative,
                              currentLearning: _currentLearning,
                              onSave: (native, learning) {
                                setState(() {
                                  _currentNative = native;
                                  _currentLearning = learning;
                                });
                                w.onUpdateProfile(
                                  _nameController.text,
                                  native,
                                  learning,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      title: const Text('Learning Language'),
                      trailing: Text(
                        _currentLearning,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LanguageSetupScreen(
                              currentNative: _currentNative,
                              currentLearning: _currentLearning,
                              onSave: (native, learning) {
                                setState(() {
                                  _currentNative = native;
                                  _currentLearning = learning;
                                });
                                w.onUpdateProfile(
                                  _nameController.text,
                                  native,
                                  learning,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.bookmark,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Saved Readings'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${w.globalPosts.where((p) => p.isSaved).length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SavedPostsScreen(
                              savedPosts: w.globalPosts
                                  .where((p) => p.isSaved)
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Night Reading Mode'),
              trailing: Switch(
                value: w.isDarkMode,
                onChanged: (val) => w.onToggleTheme(),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Notifications'),
              trailing: Switch(
                value: true,
                onChanged: (val) {},
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.apps,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('App Icon Preview'),
              subtitle: const Text('How Parley appears on your home screen'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Parley App Icon'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C5E4E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Parley',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('A sanctuary for language learners.'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.security,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Privacy & Safety'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WelcomeScreen(
                          isDarkMode: w.isDarkMode,
                          onToggleTheme: w.onToggleTheme,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
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

// ---------------------------------------------------------
// SAVED POSTS SCREEN
// ---------------------------------------------------------
class SavedPostsScreen extends StatelessWidget {
  final List<PostItem> savedPosts;
  const SavedPostsScreen({super.key, required this.savedPosts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Readings')),
      body: savedPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 60,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No saved posts yet.',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedPosts.length,
              itemBuilder: (context, index) {
                final post = savedPosts[index];
                final Color avatarColor = post.color == 'orange'
                    ? Colors.orange
                    : (post.color == 'teal'
                          ? Colors.teal
                          : Theme.of(context).colorScheme.primary);

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
                              backgroundColor: avatarColor,
                              backgroundImage: post.avatarUrl.isNotEmpty
                                  ? NetworkImage(post.avatarUrl)
                                  : null,
                              child: post.avatarUrl.isEmpty
                                  ? Text(
                                      post.initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  post.time,
                                  style: TextStyle(
                                    color: Theme.of(context).disabledColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          post.content,
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------
// LANGUAGE SETUP SCREEN
// ---------------------------------------------------------
class LanguageSetupScreen extends StatefulWidget {
  final String currentNative;
  final String currentLearning;
  final Function(String, String) onSave;

  const LanguageSetupScreen({
    super.key,
    required this.currentNative,
    required this.currentLearning,
    required this.onSave,
  });

  @override
  State createState() => _LanguageSetupScreenState();
}

class _LanguageSetupScreenState extends State {
  late String _selectedNative;
  late String _selectedLearning;

  final List _languages = [
    'Afrikaans',
    'Albanian',
    'Amharic',
    'Arabic',
    'Armenian',
    'Azerbaijani',
    'Bengali',
    'Bulgarian',
    'Burmese',
    'Catalan',
    'Chinese (Mandarin)',
    'Croatian',
    'Czech',
    'Danish',
    'Dutch',
    'English',
    'Estonian',
    'Filipino',
    'Finnish',
    'French',
    'Georgian',
    'German',
    'Greek',
    'Gujarati',
    'Hebrew',
    'Hindi',
    'Hungarian',
    'Icelandic',
    'Indonesian',
    'Irish',
    'Italian',
    'Japanese',
    'Kannada',
    'Kazakh',
    'Khmer',
    'Korean',
    'Lao',
    'Latvian',
    'Lithuanian',
    'Macedonian',
    'Malay',
    'Malayalam',
    'Maltese',
    'Marathi',
    'Mongolian',
    'Nepali',
    'Norwegian',
    'Persian',
    'Polish',
    'Portuguese',
    'Punjabi',
    'Romanian',
    'Russian',
    'Serbian',
    'Sinhala',
    'Slovak',
    'Slovenian',
    'Somali',
    'Spanish',
    'Swahili',
    'Swedish',
    'Tamil',
    'Telugu',
    'Thai',
    'Turkish',
    'Ukrainian',
    'Urdu',
    'Uzbek',
    'Vietnamese',
    'Welsh',
    'Zulu',
  ];

  @override
  void initState() {
    super.initState();
    final w = widget as LanguageSetupScreen;
    _selectedNative = w.currentNative;
    _selectedLearning = w.currentLearning;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as LanguageSetupScreen;
    return Scaffold(
      appBar: AppBar(title: const Text('Language Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select your languages',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This helps us find the perfect language partners for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 40),
            DropdownButtonFormField(
              value: _selectedNative,
              decoration: InputDecoration(
                labelText: 'I speak (Native Language)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              isExpanded: true,
              items: _languages
                  .map(
                    (lang) => DropdownMenuItem(
                      value: lang as String,
                      child: Text(lang, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedNative = val as String),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              value: _selectedLearning,
              decoration: InputDecoration(
                labelText: 'I am learning (Target Language)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              isExpanded: true,
              items: _languages
                  .map(
                    (lang) => DropdownMenuItem(
                      value: lang as String,
                      child: Text(lang, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedLearning = val as String),
            ),
            const Spacer(),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  w.onSave(_selectedNative, _selectedLearning);
                  Navigator.pop(context);
                },
                child: const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// PARTNERS SCREEN
// ---------------------------------------------------------
class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List _allPartners = const [
    Partner(
      name: 'John from USA',
      flag: '🇺🇸',
      nativeLang: 'English',
      learningLang: 'Spanish',
      bio:
          'Hi! I am John. I love traveling and I want to practice Spanish every day. I can help you with English!',
      handle: '@john_usa',
    ),
    Partner(
      name: 'Emma from UK',
      flag: '🇬🇧',
      nativeLang: 'English',
      learningLang: 'French',
      bio:
          'Hello! I am a student from London. I want to find a French partner to chat with about books and movies.',
      handle: '@emma_uk',
    ),
    Partner(
      name: 'Ahmed from Egypt',
      flag: '🇪🇬',
      nativeLang: 'Arabic',
      learningLang: 'English',
      bio:
          'I am an engineering student. I want to improve my English speaking skills and I can teach you Arabic!',
      handle: '@ahmed_eg',
    ),
    Partner(
      name: 'Carlos from Spain',
      flag: '🇪🇸',
      nativeLang: 'Spanish',
      learningLang: 'English',
      bio:
          'Hola! I love football and music. Looking for someone to practice English with.',
      handle: '@carlos_es',
    ),
  ];

  final List _bookClubs = [
    {
      'name': 'Shakespeare Readers',
      'desc': 'Analyzing the sonnets and plays of William Shakespeare.',
      'icon': Icons.menu_book,
      'members': 124,
      'color': Colors.orange,
    },
    {
      'name': 'Classic English Poetry',
      'desc': 'Reading Wordsworth, Keats, and modern poets.',
      'icon': Icons.auto_stories,
      'members': 89,
      'color': Colors.blue,
    },
    {
      'name': 'Modern Fiction Book Club',
      'desc': 'Discussing contemporary English novels.',
      'icon': Icons.library_books,
      'members': 210,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredPartners = _allPartners.where((item) {
      final partner = item as Partner;
      final matchesSearch =
          partner.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          partner.handle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _selectedFilter == 'All' || partner.nativeLang == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Fellow Readers')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Literary Circles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _bookClubs.length,
                itemBuilder: (context, index) {
                  final club = _bookClubs[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookClubScreen(
                              clubName: club['name'] as String,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (club['color'] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (club['color'] as Color).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              club['icon'] as IconData,
                              color: club['color'] as Color,
                              size: 30,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              club['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${club['members']} members',
                              style: TextStyle(
                                color: Theme.of(context).disabledColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Find Language Partners',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name or @handle...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: ['All', 'English', 'Spanish', 'Arabic'].map((lang) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(lang),
                      selected: _selectedFilter == lang,
                      onSelected: (selected) =>
                          setState(() => _selectedFilter = lang),
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                      backgroundColor: Theme.of(context).cardColor,
                      labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            if (filteredPartners.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'No partners found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filteredPartners.length,
                itemBuilder: (context, index) {
                  final partner = filteredPartners[index] as Partner;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Text(
                        partner.flag,
                        style: const TextStyle(fontSize: 30),
                      ),
                      title: Text(
                        partner.handle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${partner.name} • Native: ${partner.nativeLang}',
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              name: partner.name,
                              flag: partner.flag,
                              nativeLang: partner.nativeLang,
                              learningLang: partner.learningLang,
                              bio: partner.bio,
                              handle: partner.handle,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// BOOK CLUB SCREEN
// ---------------------------------------------------------
class BookClubScreen extends StatefulWidget {
  final String clubName;
  const BookClubScreen({super.key, required this.clubName});

  @override
  State createState() => _BookClubScreenState();
}

class _BookClubScreenState extends State {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List _messages = [
    ChatMessage(
      text: "Has anyone read 'Pride and Prejudice'?",
      isMe: false,
      translation: "Has anyone read 'Pride and Prejudice'?",
    ),
    ChatMessage(
      text: "Yes! It's my favorite book.",
      isMe: true,
      translation: "",
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _messages.add(
          ChatMessage(
            text: _controller.text.trim(),
            isMe: true,
            translation: "",
          ),
        );
        _controller.clear();
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as BookClubScreen;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.clubName, style: const TextStyle(fontSize: 18)),
            Text(
              '124 members',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index] as ChatMessage;
                return Column(
                  crossAxisAlignment: msg.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: msg.isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isMe
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: msg.isMe
                                ? Radius.zero
                                : const Radius.circular(16),
                            bottomLeft: msg.isMe
                                ? const Radius.circular(16)
                                : Radius.zero,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!msg.isMe)
                              const Text(
                                '@reader_99',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: msg.isMe
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                fontSize: 15,
                              ),
                            ),
                            if (!msg.isMe && msg.translation.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  msg.translation,
                                  style: TextStyle(
                                    color: Theme.of(context).disabledColor,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
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

// ---------------------------------------------------------
// PARTNER PROFILE SCREEN
// ---------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  final String name;
  final String flag;
  final String nativeLang;
  final String learningLang;
  final String bio;
  final String handle;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.flag,
    required this.nativeLang,
    required this.learningLang,
    required this.bio,
    required this.handle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 10),
            Text(
              handle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text('Native: $nativeLang'),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                ),
                const SizedBox(width: 10),
                Chip(
                  label: Text('Learning: $learningLang'),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About Me',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              bio,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: Text('Message $handle'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(name: handle, flag: flag),
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

// ---------------------------------------------------------
// PRACTICE SCREEN
// ---------------------------------------------------------
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spoken Practice')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                'This is a language learning space. No religious discussions, no political arguments, no hate speech. Be respectful.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoCallScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.videocam),
              label: const Text('Start Video Practice'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// FAKE VIDEO CALL SCREEN
// ---------------------------------------------------------
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State {
  bool _isMuted = false;
  bool _isVideoOff = false;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _seconds++;
        });
        return true;
      }
      return false;
    });
  }

  String get _formattedTime {
    int minutes = _seconds ~/ 60;
    int secs = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A18),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFF2C5E4E),
                  child: Icon(Icons.person, size: 70, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Connected with @kenji_jp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Practice time: $_formattedTime',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 110,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30, width: 2),
                image: const DecorationImage(
                  image: NetworkImage('https://picsum.photos/200/300'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white54, size: 40),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.flag, color: Colors.redAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ReportScreen(reportedUser: '@kenji_jp'),
                      ),
                    );
                  },
                ),
                const Text('Report', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'mute',
                  backgroundColor: _isMuted ? Colors.red : Colors.white24,
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                  child: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'end',
                  backgroundColor: Colors.red,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'cam',
                  backgroundColor: _isVideoOff ? Colors.red : Colors.white24,
                  onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
                  child: Icon(
                    _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    color: Colors.white,
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

// ---------------------------------------------------------
// CREATE POST BOTTOM SHEET
// ---------------------------------------------------------
class _CreatePostSheet extends StatefulWidget {
  final Function(String) onPost;
  const _CreatePostSheet({required this.onPost});

  @override
  State createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State {
  final TextEditingController _controller = TextEditingController();

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
          const Text(
            'Write a Post',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Share a literary thought, a language question, or start a debate...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              w.onPost(_controller.text);
              Navigator.pop(context);
            },
            child: const Text('Publish to the Feed'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// MOCK VOICE NOTE PLAYER
// ---------------------------------------------------------
class _VoiceNoteBubble extends StatefulWidget {
  final String duration;
  final bool isMe;

  const _VoiceNoteBubble({required this.duration, required this.isMe});

  @override
  State<_VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<_VoiceNoteBubble> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.isMe
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 270),
      decoration: BoxDecoration(
        color: widget.isMe
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: widget.isMe ? Radius.zero : const Radius.circular(18),
          bottomLeft: widget.isMe ? const Radius.circular(18) : Radius.zero,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _isPlaying = !_isPlaying),
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: foreground,
              size: 32,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(22, (index) {
                    final heights = [
                      8,
                      15,
                      11,
                      20,
                      13,
                      24,
                      10,
                      17,
                      22,
                      12,
                      18,
                      8,
                      21,
                      14,
                      25,
                      11,
                      17,
                      9,
                      20,
                      13,
                      16,
                      8,
                    ];
                    return Expanded(
                      child: Container(
                        height: heights[index].toDouble(),
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: foreground?.withOpacity(
                            _isPlaying ? 0.95 : 0.65,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying ? 'Playing (preview only)' : widget.duration,
                  style: TextStyle(
                    fontSize: 10,
                    color: foreground?.withOpacity(0.8),
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
