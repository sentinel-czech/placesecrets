import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/locale_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/account_data_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../auth/providers/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _geofenceRadius = AppConstants.defaultGeofenceRadiusMeters;
  bool _notificationsEnabled = true;
  final _backupEmailController = TextEditingController();
  bool _backupEmailLoading = false;
  final _handleController = TextEditingController();
  bool _handleLoading = false;
  String? _handleError;
  String? _avatarUrl;
  bool _avatarLoading = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadBackupEmail();
    _loadHandle();
    _loadAvatar();
  }

  @override
  void dispose() {
    _backupEmailController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _geofenceRadius = prefs.getDouble(AppConstants.prefGeofenceRadius) ??
          AppConstants.defaultGeofenceRadiusMeters;
      _notificationsEnabled =
          prefs.getBool(AppConstants.prefNotificationsEnabled) ?? true;
    });
  }

  Future<void> _loadBackupEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || (user.isAnonymous)) return;
    try {
      final data = await Supabase.instance.client
          .from('user_profiles')
          .select('backup_email')
          .eq('user_id', user.id)
          .maybeSingle();
      if (data != null && data['backup_email'] != null) {
        _backupEmailController.text = data['backup_email'] as String;
      }
    } catch (_) {}
  }

  Future<void> _saveBackupEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _backupEmailLoading = true);
    try {
      final email = _backupEmailController.text.trim();
      await Supabase.instance.client.from('user_profiles').upsert({
        'user_id': user.id,
        'backup_email': email.isEmpty ? null : email,
      }, onConflict: 'user_id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup email saved')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save backup email')),
        );
      }
    } finally {
      if (mounted) setState(() => _backupEmailLoading = false);
    }
  }

  Future<void> _loadHandle() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || (user.isAnonymous)) return;
    try {
      final data = await Supabase.instance.client
          .from('user_profiles')
          .select('display_name')
          .eq('user_id', user.id)
          .maybeSingle();
      if (data != null && data['display_name'] != null) {
        _handleController.text = data['display_name'] as String;
      }
    } catch (_) {}
  }

  Future<void> _saveHandle() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final handle = _handleController.text.trim();
    if (handle.isNotEmpty && !RegExp(r'^[a-z0-9_]{3,50}$').hasMatch(handle)) {
      setState(() => _handleError = '3-50 chars: lowercase, numbers, underscores');
      return;
    }
    setState(() {
      _handleLoading = true;
      _handleError = null;
    });
    try {
      await Supabase.instance.client.from('user_profiles').upsert({
        'user_id': user.id,
        'display_name': handle.isEmpty ? null : handle,
      }, onConflict: 'user_id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Handle saved')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save handle')),
        );
      }
    } finally {
      if (mounted) setState(() => _handleLoading = false);
    }
  }

  String _avatarInitial(AppAuthState authState) {
    final source = authState.displayName ?? authState.email ?? '';
    return source.isNotEmpty ? source[0].toUpperCase() : '?';
  }

  Future<void> _loadAvatar() async {
    try {
      final url = await ref.read(profileRepositoryProvider).getAvatarUrl();
      if (mounted && url != null) setState(() => _avatarUrl = url);
    } catch (_) {}
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _avatarLoading = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final url = await ref.read(profileRepositoryProvider).uploadAvatar(
            bytes,
            fileExtension: ext,
            cacheBust: DateTime.now().millisecondsSinceEpoch,
          );
      if (mounted) {
        setState(() => _avatarUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo')),
        );
      }
    } finally {
      if (mounted) setState(() => _avatarLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Language
          _SectionHeader(title: 'Language'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('App language'),
            subtitle: Text(_currentLanguageLabel(ref.watch(appLocaleProvider))),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguagePicker,
          ),

          const Divider(),

          // Audio & Location
          _SectionHeader(title: 'Audio & Location'),
          ListTile(
            leading: const Icon(Icons.radar),
            title: const Text('Geofence radius'),
            subtitle: Text('${_geofenceRadius.round()} meters'),
            onTap: _showGeofenceSlider,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Alert when near a point of interest'),
            value: _notificationsEnabled,
            onChanged: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(AppConstants.prefNotificationsEnabled, v);
              setState(() => _notificationsEnabled = v);
            },
          ),

          const Divider(),

          // Account
          _SectionHeader(title: 'Account'),
          if (authState.isAuthenticated)
            ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundImage:
                    _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null
                    ? Text(_avatarInitial(authState))
                    : null,
              ),
              title: const Text('Profile photo'),
              subtitle: const Text('Shown on your profile'),
              trailing: _avatarLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.photo_camera_outlined),
                      onPressed: _pickAndUploadAvatar,
                    ),
              onTap: _avatarLoading ? null : _pickAndUploadAvatar,
            ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(authState.isAuthenticated ? 'Signed in' : 'Anonymous'),
            subtitle: Text(
              authState.email ?? 'Sign in to sync your data across devices',
            ),
            trailing: authState.isAuthenticated
                ? null
                : const Icon(Icons.chevron_right),
            onTap: authState.isAuthenticated
                ? null
                : () => context.push('/auth'),
          ),
          if (authState.isAuthenticated && !authState.isEmailVerified)
            ListTile(
              leading: Icon(Icons.mark_email_unread_outlined,
                  color: theme.colorScheme.error),
              title: const Text('Email not verified'),
              subtitle: const Text('Tap to resend the verification email'),
              trailing: TextButton(
                onPressed: _resendVerification,
                child: const Text('Resend'),
              ),
              onTap: _resendVerification,
            ),
          if (authState.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('My access'),
              subtitle: const Text('Free quota and what you own'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/account/access'),
            ),
          if (authState.isAuthenticated && authState.userNumber != null)
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('User Number'),
              subtitle: Text('#${authState.userNumber}'),
            ),
          if (authState.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Handle'),
              subtitle: TextField(
                controller: _handleController,
                decoration: InputDecoration(
                  hintText: 'your_handle',
                  prefixText: '@',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
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
              trailing: _handleLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveHandle,
                    ),
            ),
          if (authState.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Backup Email'),
              subtitle: TextField(
                controller: _backupEmailController,
                decoration: const InputDecoration(
                  hintText: 'backup@example.com',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              trailing: _backupEmailLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveBackupEmail,
                    ),
            ),
          if (authState.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangePasswordDialog,
            ),
          if (authState.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.alternate_email_outlined),
              title: const Text('Change email'),
              subtitle: Text(authState.email ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangeEmailDialog,
            ),
          if (authState.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Payment history'),
              subtitle: const Text('Receipts and purchase history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/account/receipts'),
            ),

          const Divider(),

          // Community
          _SectionHeader(title: 'Community'),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Become a guide'),
            subtitle: const Text('Write POI content and get recognized'),
            trailing: const Icon(Icons.open_in_new),
            // Contributor onboarding (POI editor, PIN) lives on the web portal.
            onTap: _openContributorRegistration,
          ),

          if (authState.isAuthenticated) ...[
            const Divider(),
            _SectionHeader(title: 'Privacy & data'),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export my data'),
              subtitle: const Text('Download a copy of your data (GDPR)'),
              trailing: _exporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right),
              onTap: _exporting ? null : _exportData,
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              title: Text('Delete account',
                  style: TextStyle(color: theme.colorScheme.error)),
              subtitle: const Text('Permanently delete your account and data'),
              onTap: _confirmDeleteAccount,
            ),
          ],

          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About PlaceSecrets'),
            onTap: () => _showAbout(),
          ),

          if (authState.isAuthenticated) ...[
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Sign out',
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () async {
                await ref.read(authStateProvider.notifier).signOut();
              },
            ),
          ],
        ],
      ),
    );
  }

  String _currentLanguageLabel(Locale? locale) {
    if (locale == null) return 'System default';
    return kSupportedLanguages[locale.languageCode] ?? locale.languageCode;
  }

  Future<void> _saveLanguageToProfile(String code) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      await Supabase.instance.client.from('user_profiles').upsert(
        {'user_id': user.id, 'language': code},
        onConflict: 'user_id',
      );
    } catch (_) {/* non-fatal: local preference already applied */}
  }

  void _showLanguagePicker() {
    final current = ref.read(appLocaleProvider)?.languageCode;
    showDialog(
      context: context,
      builder: (dialogCtx) => SimpleDialog(
        title: const Text('App language'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              await ref.read(appLocaleProvider.notifier).setLocale(null);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Row(
              children: [
                Expanded(child: Text('System default',
                    style: TextStyle(
                        fontWeight: current == null
                            ? FontWeight.bold
                            : FontWeight.normal))),
                if (current == null) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
          for (final entry in kSupportedLanguages.entries)
            SimpleDialogOption(
              onPressed: () async {
                await ref
                    .read(appLocaleProvider.notifier)
                    .setLocale(entry.key);
                await _saveLanguageToProfile(entry.key);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.value,
                        style: TextStyle(
                            fontWeight: current == entry.key
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                  if (current == entry.key) const Icon(Icons.check, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showGeofenceSlider() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Geofence Radius'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_geofenceRadius.round()} meters'),
              Slider(
                value: _geofenceRadius,
                min: 50,
                max: 500,
                divisions: 9,
                label: '${_geofenceRadius.round()}m',
                onChanged: (v) {
                  setDialogState(() => _geofenceRadius = v);
                  setState(() => _geofenceRadius = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble(
                    AppConstants.prefGeofenceRadius, _geofenceRadius);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final data =
          await AccountDataRepository(Supabase.instance.client).exportData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/placesecrets-data.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)],
          subject: 'PlaceSecrets data export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export data')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account, purchases, ratings and '
          'travel history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AccountDataRepository(Supabase.instance.client).deleteAccount();
      // Account is gone server-side; reset to a fresh anonymous session.
      await ref.read(authStateProvider.notifier).signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete account. Please try again.')),
        );
      }
    }
  }

  Future<void> _openContributorRegistration() async {
    final uri = Uri.parse('https://placesecrets.app/register/contributor');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the registration page')),
        );
      }
    }
  }

  Future<void> _resendVerification() async {
    try {
      await ref.read(authStateProvider.notifier).resendVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send verification email')),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final controller = TextEditingController();
    String? error;
    bool busy = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New password',
              hintText: 'At least 8 characters',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final pwd = controller.text;
                      if (pwd.length < 8) {
                        setDialogState(() =>
                            error = 'Password must be at least 8 characters');
                        return;
                      }
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await ref
                            .read(authStateProvider.notifier)
                            .updatePassword(pwd);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated')),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          busy = false;
                          error = 'Could not update password';
                        });
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeEmailDialog() {
    final controller = TextEditingController(
      text: Supabase.instance.client.auth.currentUser?.email ?? '',
    );
    String? error;
    bool busy = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'New email',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A confirmation link will be sent to the new address. '
                'The change applies after you confirm it.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final email = controller.text.trim();
                      if (!email.contains('@') || email.length < 5) {
                        setDialogState(
                            () => error = 'Enter a valid email address');
                        return;
                      }
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await ref
                            .read(authStateProvider.notifier)
                            .updateEmail(email);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Confirmation email sent to the new address')),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          busy = false;
                          error = 'Could not update email';
                        });
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'PlaceSecrets',
      applicationVersion: '1.0.0',
      applicationLegalese: '\u00a9 2024 PlaceSecrets',
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
