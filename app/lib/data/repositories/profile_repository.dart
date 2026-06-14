import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'profile_repository.g.dart';

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) =>
    ProfileRepository(Supabase.instance.client);

/// Thrown when an avatar upload is attempted without a real (non-anonymous)
/// signed-in account.
class AvatarAuthRequiredException implements Exception {
  const AvatarAuthRequiredException();
  @override
  String toString() => 'You must be signed in to upload an avatar.';
}

/// Profile photo storage. Mirrors the web flow: upload to the public `avatars`
/// bucket under `<uid>/avatar.<ext>` (owner-write RLS, migration 0447), then
/// persist the public URL to `user_profiles.avatar_url`.
class ProfileRepository {
  final SupabaseClient _supabase;
  ProfileRepository(this._supabase);

  Future<String?> getAvatarUrl() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    final data = await _supabase
        .from('user_profiles')
        .select('avatar_url')
        .eq('user_id', user.id)
        .maybeSingle();
    return data?['avatar_url'] as String?;
  }

  /// Uploads [bytes] as the user's avatar and returns a cache-busted public URL.
  Future<String> uploadAvatar(
    Uint8List bytes, {
    required String fileExtension,
    int cacheBust = 0,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const AvatarAuthRequiredException();
    }
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final path = '${user.id}/avatar.$safeExt';

    await _supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(safeExt),
          ),
        );

    final base = _supabase.storage.from('avatars').getPublicUrl(path);
    final publicUrl = cacheBust > 0 ? '$base?t=$cacheBust' : base;

    await _supabase.from('user_profiles').upsert(
      {'user_id': user.id, 'avatar_url': publicUrl},
      onConflict: 'user_id',
    );
    return publicUrl;
  }

  static String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
