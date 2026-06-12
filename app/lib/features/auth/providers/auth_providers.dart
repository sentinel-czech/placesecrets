import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  AppAuthState build() {
    final session = Supabase.instance.client.auth.currentSession;
    return AppAuthState(
      user: session?.user,
      isAnonymous: session?.user.isAnonymous ?? true,
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

  Future<void> signUp(String email, String password, {String? handle}) async {
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
        if (handle != null && handle.isNotEmpty) {
          await Supabase.instance.client.from('user_profiles').upsert(
            {'user_id': response.user!.id, 'display_name': handle},
            onConflict: 'user_id',
          );
        }
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
      if (handle != null && handle.isNotEmpty) {
        await Supabase.instance.client.from('user_profiles').upsert(
          {'user_id': response.user!.id, 'display_name': handle},
          onConflict: 'user_id',
        );
      }
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
          .select('user_number, backup_email, display_name')
          .eq('user_id', userId)
          .maybeSingle();
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
}
