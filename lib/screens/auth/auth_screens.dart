import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../services/supabase_client.dart';

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
                    onPressed: _isSigningInWithGoogle ? null : _signInWithGoogle,
                    icon: _isSigningInWithGoogle
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.g_mobiledata, size: 30),
                    label: Text(_isSigningInWithGoogle ? 'Connecting to Google...' : 'Continue with Google'),
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
                        MaterialPageRoute(builder: (context) => const EmailAuthScreen()),
                      );
                    },
                    icon: const Icon(Icons.email),
                    label: const Text('Continue with Email'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
    if (password.length <= 5) {
      setState(() => _errorMessage = 'Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      if (_isLoginMode) {
        await supabase.auth.signInWithPassword(email: email, password: password);
      } else {
        final response = await supabase.auth.signUp(email: email, password: password);
        if (response.session == null && mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Account created! Please check your email inbox to confirm, then sign in.';
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
      appBar: AppBar(title: Text(_isLoginMode ? 'Sign In' : 'Create Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.auto_stories, size: 56, color: Theme.of(context).colorScheme.primary),
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
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                if (_isLoginMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: _resetPassword, child: const Text('Forgot Password?')),
                  )
                else
                  const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isLoginMode ? 'Sign In' : 'Create Account'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    _isLoginMode = !_isLoginMode;
                    _errorMessage = '';
                  }),
                  child: Text(_isLoginMode ? "Don't have an account? Create one" : 'Already have an account? Sign in'),
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

    final rawHandle = _handleController.text.trim().toLowerCase().replaceFirst('@', '');

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
          TextButton(onPressed: () => supabase.auth.signOut(), child: const Text('Sign Out')),
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
                const Text('Join the Library', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                    backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty) ? NetworkImage(_avatarUrl!) : null,
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
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
