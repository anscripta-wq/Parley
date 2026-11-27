import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../services/supabase_client.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isGoogleLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://anscripta-wq.github.io/Parley/',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text('Parley', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('Literary Language Exchange', style: TextStyle(fontSize: 16, color: Theme.of(context).disabledColor, fontStyle: FontStyle.italic)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(
                    _isGoogleLoading ? 'Connecting to Google...' : 'Continue with Google',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Continue with Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: _isGoogleLoading
                      ? null
                      : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailAuthScreen())),
                ),
              ),
            ],
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
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
    if (email.isEmpty || password.length <= 5) {
      setState(() => _errorMessage = 'Enter a valid email and a password of at least 6 characters.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(email: email, password: password);
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        final res = await supabase.auth.signUp(email: email, password: password);
        if (mounted) {
          if (res.session != null) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          } else {
            setState(() {
              _isLoading = false;
              _isLogin = true;
              _errorMessage = 'Account created! Please check your email or sign in.';
            });
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() { _errorMessage = e.message; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Unexpected error: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Sign In' : 'Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text(_errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                ),
              ),
              TextButton(
                onPressed: () => setState(() { _isLogin = !_isLogin; _errorMessage = ''; }),
                child: Text(_isLogin ? 'Need an account? Sign Up' : 'Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  final User user;
  final void Function(UserProfile profile) onProfileSaved;

  const OnboardingScreen({super.key, required this.user, required this.onProfileSaved});

  @override
  State createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State {
  final _handleController = TextEditingController();
  final _bioController = TextEditingController();
  String _gender = 'Male';
  String _country = 'Pakistan';
  String _nativeLang = 'Urdu';
  String _learningLang = 'English (US) 🇺🇸';
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future _saveProfile() async {
    final w = widget as OnboardingScreen;
    final cleanHandle = _handleController.text.trim().toLowerCase().replaceFirst('@', '');
    if (cleanHandle.length <= 2) {
      setState(() => _errorMessage = 'Username must be at least 3 characters.');
      return;
    }
    setState(() { _isSaving = true; _errorMessage = ''; });
    try {
      final bioText = _bioController.text.trim().isEmpty
          ? 'Practicing $_learningLang through conversation and reading.'
          : _bioController.text.trim();

      final inserted = await supabase.from('profiles').upsert({
        'id': w.user.id,
        'handle': cleanHandle,
        'gender': _gender,
        'country': _country,
        'native_lang': _nativeLang,
        'learning_lang': _learningLang,
        'bio': bioText,
      }).select().single();

      w.onProfileSaved(UserProfile.fromMap(inserted));
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.code == '23505' ? 'That @username is already taken.' : e.message;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not save profile: $e'; _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final countries = kCountryFlags.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Reader Profile'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async => await supabase.auth.signOut())],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _handleController, decoration: const InputDecoration(labelText: 'Username', prefixText: '@', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('👨 Male')),
                      selected: _gender == 'Male',
                      onSelected: (_) => setState(() => _gender = 'Male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('👩 Female')),
                      selected: _gender == 'Female',
                      onSelected: (_) => setState(() => _gender = 'Female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                initialValue: _country,
                decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                items: countries.map((c) => DropdownMenuItem(value: c, child: Text('${countryToFlag(c)}  $c'))).toList(),
                onChanged: (val) => setState(() => _country = (val ?? 'Pakistan').toString()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                initialValue: _nativeLang,
                decoration: const InputDecoration(labelText: 'Native Language', border: OutlineInputBorder()),
                items: kSupportedLanguages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                onChanged: (val) => setState(() => _nativeLang = (val ?? 'Urdu').toString()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                initialValue: _learningLang,
                decoration: const InputDecoration(labelText: 'Learning Language', border: OutlineInputBorder()),
                items: kSupportedLanguages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                onChanged: (val) => setState(() => _learningLang = (val ?? 'English (US) 🇺🇸').toString()),
              ),
              const SizedBox(height: 16),
              TextField(controller: _bioController, maxLines: 2, decoration: const InputDecoration(labelText: 'Short Bio (Optional)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text(_errorMessage, style: const TextStyle(color: Colors.red))),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Enter Parley', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
