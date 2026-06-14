import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/locale_provider.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  AppAuthState build() {
    // React to auth changes that happen outside the explicit methods — most
    // importantly the OAuth deep-link callback, which supabase_flutter
    // completes asynchronously after the browser returns.
    try {
      final sub = Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) {
          final user = data.session?.user;
          if (data.event == AuthChangeEvent.signedIn &&
              user != null &&
              !user.isAnonymous) {
            // Populate profile fields for externally-completed sign-ins (OAuth).
            _fetchOrCreateProfile(user.id).then((profile) {
              state = AppAuthState(
                user: user,
                isAnonymous: false,
                userNumber: profile?['user_number'] as int?,
                backupEmail: profile?['backup_email'] as String?,
                displayName: profile?['display_name'] as String?,
              );
            });
          }
        },
        onError: (Object e) => debugPrint('Auth state stream error: $e'),
      );
      ref.onDispose(sub.cancel);
    } catch (e) {
      debugPrint('Auth state listener unavailable: $e');
    }

    final session = Supabase.instance.client.auth.currentSession;
    return AppAuthState(
      user: session?.user,
      isAnonymous: session?.user.isAnonymous ?? true,
    );
  }

  /// Starts an OAuth sign-in (Google/Apple). Opens the provider in an external
  /// browser and returns to the app via the `placesecrets://login-callback`
  /// deep link, which supabase_flutter exchanges for a session; the
  /// [onAuthStateChange] listener above then updates app state.
  ///
  /// Requires the provider + redirect URL to be configured in the Supabase
  /// dashboard (see app/BUILD.md). Cannot be verified without a device.
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await Supabase.instance.client.auth.signInWithOAuth(
      provider,
      redirectTo: 'placesecrets://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  void setUser(User? user) {
    state = AppAuthState(
      user: user,
      isAnonymous: user?.isAnonymous ?? true,
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    final response = await Supabase.instance.client.auth
        .signInWithPassword(email: email, password: password);
    final profile = await _fetchOrCreateProfile(response.user!.id);
    state = AppAuthState(
      user: response.user,
      isAnonymous: false,
      userNumber: profile?['user_number'] as int?,
      backupEmail: profile?['backup_email'] as String?,
      displayName: profile?['display_name'] as String?,
    );
  }

  Future<void> signUp(
    String email,
    String password, {
    String? handle,
    bool acceptedTerms = false,
  }) async {
    if (!acceptedTerms) {
      throw const TermsNotAcceptedException();
    }
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isAnon = currentUser?.isAnonymous ?? false;

    if (isAnon) {
      // Migrate anonymous user to email account
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: email, password: password),
      );
      if (response.user != null) {
        // Trigger data migration
        await Supabase.instance.client.functions.invoke(
          'migrate-anonymous-data',
          body: {'user_id': response.user!.id},
        );
        await _saveConsentAndHandle(response.user!.id, handle);
        final profile = await _fetchOrCreateProfile(response.user!.id);
        state = AppAuthState(
          user: response.user,
          isAnonymous: false,
          userNumber: profile?['user_number'] as int?,
          backupEmail: profile?['backup_email'] as String?,
          displayName: profile?['display_name'] as String?,
        );
      }
    } else {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      await _saveConsentAndHandle(response.user!.id, handle);
      final profile = await _fetchOrCreateProfile(response.user!.id);
      state = AppAuthState(
        user: response.user,
        isAnonymous: false,
        userNumber: profile?['user_number'] as int?,
        backupEmail: profile?['backup_email'] as String?,
        displayName: profile?['display_name'] as String?,
      );
    }
  }

  /// Persists Terms/Privacy consent timestamps (matching the web register flow:
  /// `terms_accepted_at` / `privacy_accepted_at`) and the optional handle.
  Future<void> _saveConsentAndHandle(String userId, String? handle) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'user_id': userId,
      'terms_accepted_at': now,
      'privacy_accepted_at': now,
    };
    if (handle != null && handle.isNotEmpty) {
      payload['display_name'] = handle;
    }
    await Supabase.instance.client
        .from('user_profiles')
        .upsert(payload, onConflict: 'user_id');
  }

  /// Re-sends the signup confirmation email for the current/given address.
  Future<void> resendVerification([String? email]) async {
    final target = email ?? Supabase.instance.client.auth.currentUser?.email;
    if (target == null) return;
    await Supabase.instance.client.auth.resend(
      type: OtpType.signup,
      email: target,
    );
  }

  /// Updates the account password (user must be signed in).
  Future<void> updatePassword(String newPassword) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Updates the primary email. Supabase sends a confirmation to the new
  /// address; the change only takes effect once confirmed.
  Future<void> updateEmail(String newEmail) async {
    final response = await Supabase.instance.client.auth.updateUser(
      UserAttributes(email: newEmail),
    );
    setUser(response.user);
  }

  Future<void> resetPassword(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
  }

  Future<Map<String, dynamic>?> _fetchOrCreateProfile(String userId) async {
    try {
      // Upsert to ensure profile exists, then fetch
      await Supabase.instance.client
          .from('user_profiles')
          .upsert({'user_id': userId}, onConflict: 'user_id');
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('user_number, backup_email, display_name, language')
          .eq('user_id', userId)
          .maybeSingle();
      // Apply the server-side language preference app-wide (parity with web).
      // Skip the column default ('en') so signing in never force-flips a
      // system-default device to English — only an explicit non-default choice
      // propagates. The user's explicit local pick already persists locally.
      final language = response?['language'] as String?;
      if (language != null && language != 'en') {
        await ref.read(appLocaleProvider.notifier).applyFromProfile(language);
      }
      return response;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    // Re-create anonymous session
    await Supabase.instance.client.auth.signInAnonymously();
    final user = Supabase.instance.client.auth.currentUser;
    state = AppAuthState(user: user, isAnonymous: true);
  }
}

/// Thrown when sign-up is attempted without accepting the Terms/Privacy policy.
class TermsNotAcceptedException implements Exception {
  const TermsNotAcceptedException();
  @override
  String toString() => 'You must accept the Terms and Privacy Policy.';
}

class AppAuthState {
  final User? user;
  final bool isAnonymous;
  final int? userNumber;
  final String? backupEmail;
  final String? displayName;

  const AppAuthState({
    this.user,
    this.isAnonymous = true,
    this.userNumber,
    this.backupEmail,
    this.displayName,
  });

  bool get isAuthenticated => user != null && !isAnonymous;
  String? get userId => user?.id;
  String? get email => user?.email;
  bool get needsHandle => isAuthenticated && displayName == null;
  bool get isEmailVerified => user?.emailConfirmedAt != null;
}
