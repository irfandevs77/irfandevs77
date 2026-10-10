import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';
import 'admin_login_page.dart';
import 'admin_workspace.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String? _checkedUid;
  Future<Map<String, dynamic>>? _claimsCheck;

  void _refreshClaims(User user) {
    setState(() {
      _checkedUid = user.uid;
      _claimsCheck = FirebaseService.readClaims(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService.auth.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingPage();
        }
        final user = authSnapshot.data;
        if (user == null) return const AdminLoginPage();
        if (_checkedUid != user.uid) {
          _checkedUid = user.uid;
          _claimsCheck = FirebaseService.readClaims(user);
        }
        return FutureBuilder<Map<String, dynamic>>(
          future: _claimsCheck,
          builder: (context, claimSnapshot) {
            if (claimSnapshot.hasError) {
              return _StatusPage(
                title: 'Could not verify admin access',
                detail: claimSnapshot.error.toString(),
                actions: [
                  FilledButton(
                    onPressed: () => _refreshClaims(user),
                    child: const Text('Retry verification'),
                  ),
                  TextButton(
                    onPressed: () => FirebaseService.auth.signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              );
            }
            if (!claimSnapshot.hasData) return const _LoadingPage();
            final claims = claimSnapshot.data!;
            if (!FirebaseService.hasAdminRoleClaim(claims)) {
              final adminValue = claims.containsKey('admin')
                  ? '${claims['admin']} (${claims['admin'].runtimeType})'
                  : 'missing';
              final roleValue = claims['role']?.toString() ?? 'missing';
              return _StatusPage(
                title: 'Admin access required',
                detail:
                    'Signed in as ${user.email ?? user.uid}.\n\n'
                    'Firebase project: ${FirebaseEnvironment.projectId}\n'
                    'Token claim admin: $adminValue\n'
                    'Token claim role: $roleValue\n\n'
                    'This app and your Firestore rules require the exact boolean custom claim admin: true. A role named "admin" or the string "true" is not equivalent. After setting the custom claim, refresh the token below.',
                actions: [
                  FilledButton.icon(
                    onPressed: () => _refreshClaims(user),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh admin access'),
                  ),
                  TextButton(
                    onPressed: () => FirebaseService.auth.signOut(),
                    child: const Text('Sign out and switch account'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (route) => false),
                    child: const Text('Return to website'),
                  ),
                ],
              );
            }
            return const AdminWorkspace();
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) => Theme(
    data: PortfolioTheme.light,
    child: const Scaffold(
      backgroundColor: PortfolioTheme.background,
      body: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _StatusPage extends StatelessWidget {
  const _StatusPage({
    required this.title,
    required this.detail,
    required this.actions,
  });

  final String title;
  final String detail;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Theme(
    data: PortfolioTheme.light,
    child: Scaffold(
      backgroundColor: PortfolioTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: PortfolioTheme.cyan,
                ),
                const SizedBox(height: 14),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SelectableText(detail, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
