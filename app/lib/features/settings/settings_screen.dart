import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadBackupEmail();
    _loadHandle();
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Audio & Location
          _SectionHeader(title: 'Audio & Location'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Audio Language'),
            subtitle: const Text('English'),
            onTap: _showLanguagePicker,
          ),
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
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Payment history'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show purchases in a simple dialog for now
              _showPurchaseHistory();
            },
          ),

          const Divider(),

          // Community
          _SectionHeader(title: 'Community'),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Become a guide'),
            subtitle: const Text('Write POI content and get recognized'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Deep link to web contributor registration
            },
          ),

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

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Audio Language'),
        children: [
          for (final lang in ['en', 'cs', 'de'])
            SimpleDialogOption(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(AppConstants.prefAudioLanguage, lang);
                if (mounted) Navigator.pop(context);
              },
              child: Text({
                'en': 'English',
                'cs': 'Czech',
                'de': 'German',
              }[lang]!),
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

  void _showPurchaseHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment History'),
        content: const Text(
            'Your purchase receipts are available in the PlaceSecrets web portal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
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
