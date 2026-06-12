import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_providers.dart';

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
        await authNotifier.signUp(email, password, handle: handle.isEmpty ? null : handle);
      } else {
        await authNotifier.signInWithEmail(email, password);
      }
      if (mounted) context.pop();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An error occurred. Please try again.');
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
