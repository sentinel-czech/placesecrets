import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'providers/auth_providers.dart';

/// Tappable legal link that opens the corresponding web page.
class _LegalLink extends StatelessWidget {
  final String label;
  final String path;
  final TextStyle? style;
  final Color color;
  const _LegalLink({
    required this.label,
    required this.path,
    required this.style,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse('https://placesecrets.app$path'),
        mode: LaunchMode.externalApplication,
      ),
      child: Text(
        label,
        style: style?.copyWith(
          color: color,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _handleController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  bool _resetSent = false;
  String? _handleError;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isAnonymous = authState.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Sign In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.person, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),

            if (isAnonymous)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primaryContainer),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create an account to sync your data across devices and keep your travel history safe.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outlined),
              ),
            ),

            if (_isSignUp) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _handleController,
                decoration: InputDecoration(
                  labelText: 'Handle (optional)',
                  hintText: 'your_username',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.alternate_email),
                  errorText: _handleError,
                ),
                onChanged: (value) {
                  final clean = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
                  if (clean != value) {
                    _handleController.value = TextEditingValue(
                      text: clean,
                      selection: TextSelection.collapsed(offset: clean.length),
                    );
                  }
                  if (clean.isNotEmpty && !RegExp(r'^[a-z0-9_]{3,50}$').hasMatch(clean)) {
                    setState(() => _handleError = '3-50 chars: lowercase, numbers, underscores');
                  } else {
                    setState(() => _handleError = null);
                  }
                },
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (v) =>
                          setState(() => _acceptedTerms = v ?? false),
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('I agree to the ',
                              style: theme.textTheme.bodySmall),
                          _LegalLink(
                            label: 'Terms of Service',
                            path: '/terms',
                            style: theme.textTheme.bodySmall,
                            color: theme.colorScheme.primary,
                          ),
                          Text(' and ', style: theme.textTheme.bodySmall),
                          _LegalLink(
                            label: 'Privacy Policy',
                            path: '/privacy',
                            style: theme.textTheme.bodySmall,
                            color: theme.colorScheme.primary,
                          ),
                          Text('.', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),

            if (_resetSent)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Password reset email sent. Check your inbox.',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isSignUp ? 'Create Account' : 'Sign In'),
            ),

            const SizedBox(height: 16),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('or continue with',
                    style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : () => _oauth(OAuthProvider.google),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Google'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loading ? null : () => _oauth(OAuthProvider.apple),
              icon: const Icon(Icons.apple),
              label: const Text('Apple'),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                  _error = null;
                  _resetSent = false;
                  _handleError = null;
                });
              },
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign in'
                    : "Don't have an account? Create one",
              ),
            ),

            if (!_isSignUp)
              TextButton(
                onPressed: _resetPassword,
                child: const Text('Forgot password?'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }

    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    if (_isSignUp && !_acceptedTerms) {
      setState(() =>
          _error = 'Please accept the Terms and Privacy Policy to continue');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      if (_isSignUp) {
        final handle = _handleController.text.trim();
        if (handle.isNotEmpty && !RegExp(r'^[a-z0-9_]{3,50}$').hasMatch(handle)) {
          setState(() => _error = 'Invalid handle format');
          setState(() => _loading = false);
          return;
        }
        await authNotifier.signUp(
          email,
          password,
          handle: handle.isEmpty ? null : handle,
          acceptedTerms: _acceptedTerms,
        );
        if (mounted) {
          final verified =
              ref.read(authStateProvider).isEmailVerified;
          if (!verified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Account created. Check your inbox to verify your email.'),
              ),
            );
          }
        }
      } else {
        await authNotifier.signInWithEmail(email, password);
      }
      if (mounted) context.pop();
    } on TermsNotAcceptedException {
      setState(() => _error = 'Please accept the Terms and Privacy Policy');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Launches an external browser; the session completes via deep link and
      // the auth-state listener updates state. Close this screen optimistically.
      await ref.read(authStateProvider.notifier).signInWithOAuth(provider);
      if (mounted) context.pop();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not start sign-in. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email address first');
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).resetPassword(email);
      setState(() {
        _resetSent = true;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not send reset email');
    }
  }
}
