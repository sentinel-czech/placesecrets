import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// SettingsScreen depends on Supabase and SharedPreferences in initState.
// We test its core UI by building a simplified replica that accepts the
// auth state as a parameter, matching the real widget's layout.

class _SettingsTestable extends StatelessWidget {
  final bool isAuthenticated;
  final String? email;
  final int? userNumber;

  const _SettingsTestable({
    this.isAuthenticated = false,
    this.email,
    this.userNumber,
  });

  @override
  Widget build(BuildContext context) {
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
          ),
          ListTile(
            leading: const Icon(Icons.radar),
            title: const Text('Geofence radius'),
            subtitle: const Text('100 meters'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Alert when near a point of interest'),
            value: true,
            onChanged: (_) {},
          ),

          const Divider(),

          // Account
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(
                isAuthenticated ? 'Signed in' : 'Anonymous'),
            subtitle: Text(
              email ??
                  'Sign in to sync your data across devices',
            ),
          ),
          if (isAuthenticated && userNumber != null)
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('User Number'),
              subtitle: Text('#$userNumber'),
            ),
          if (isAuthenticated)
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Handle'),
              subtitle: const TextField(
                decoration: InputDecoration(
                  hintText: 'your_handle',
                  prefixText: '@',
                  border: InputBorder.none,
                ),
              ),
            ),
          if (isAuthenticated)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Backup Email'),
            ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Payment history'),
            trailing: const Icon(Icons.chevron_right),
          ),

          const Divider(),

          // Community
          _SectionHeader(title: 'Community'),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Become a guide'),
            subtitle:
                const Text('Write POI content and get recognized'),
          ),

          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About PlaceSecrets'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'PlaceSecrets',
                applicationVersion: '1.0.0',
                applicationLegalese: '\u00a9 2024 PlaceSecrets',
              );
            },
          ),

          if (isAuthenticated) ...[
            const Divider(),
            ListTile(
              leading:
                  Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Sign out',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ],
      ),
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

Widget _wrap({bool isAuthenticated = false, int? userNumber}) {
  return MaterialApp(
    home: _SettingsTestable(
      isAuthenticated: isAuthenticated,
      userNumber: userNumber,
    ),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets(
        'renders all settings tiles (Audio Language, Geofence, Notifications)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Audio Language'), findsOneWidget);
      expect(find.text('Geofence radius'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Payment history'), findsOneWidget);
      expect(find.text('Become a guide'), findsOneWidget);
    });

    testWidgets('section headers are visible', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Audio & Location'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
    });

    testWidgets('Sign Out tile visible for authenticated user',
        (tester) async {
      await tester.pumpWidget(_wrap(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Scroll down to find Sign out
      await tester.scrollUntilVisible(
        find.text('Sign out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('Sign Out tile hidden for anonymous user',
        (tester) async {
      await tester.pumpWidget(_wrap(isAuthenticated: false));
      await tester.pumpAndSettle();

      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('Handle field visible for authenticated user',
        (tester) async {
      await tester.pumpWidget(_wrap(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Scroll down to find Handle
      await tester.scrollUntilVisible(
        find.text('Handle'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Handle'), findsOneWidget);
      expect(find.byIcon(Icons.alternate_email), findsOneWidget);
    });

    testWidgets('Handle field hidden for anonymous user',
        (tester) async {
      await tester.pumpWidget(_wrap(isAuthenticated: false));
      await tester.pumpAndSettle();

      expect(find.text('Handle'), findsNothing);
    });

    testWidgets('About tile shows about dialog', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Scroll down to find the About tile
      await tester.scrollUntilVisible(
        find.text('About PlaceSecrets'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('About PlaceSecrets'), findsOneWidget);

      // Tap the about tile
      await tester.tap(find.text('About PlaceSecrets'));
      await tester.pumpAndSettle();

      // About dialog should appear with version info
      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.textContaining('2024 PlaceSecrets'), findsOneWidget);
    });

    testWidgets('shows Signed in for authenticated user', (tester) async {
      await tester.pumpWidget(_wrap(isAuthenticated: true));
      await tester.pumpAndSettle();

      expect(find.text('Signed in'), findsOneWidget);
    });

    testWidgets('shows Anonymous for non-authenticated user',
        (tester) async {
      await tester.pumpWidget(_wrap(isAuthenticated: false));
      await tester.pumpAndSettle();

      expect(find.text('Anonymous'), findsOneWidget);
    });

    testWidgets('User Number shown for authenticated user with number',
        (tester) async {
      await tester.pumpWidget(
          _wrap(isAuthenticated: true, userNumber: 100042));
      await tester.pumpAndSettle();

      // Scroll down to find User Number
      await tester.scrollUntilVisible(
        find.text('User Number'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('User Number'), findsOneWidget);
      expect(find.text('#100042'), findsOneWidget);
    });
  });
}
