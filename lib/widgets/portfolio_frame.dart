import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;

import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';
import 'portfolio_components.dart';
import 'portfolio_search.dart';

class PortfolioFrame extends StatelessWidget {
  const PortfolioFrame({
    super.key,
    required this.activeRoute,
    required this.child,
  });

  final String activeRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PortfolioTheme.light,
      child: Scaffold(
        backgroundColor: PortfolioTheme.background,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF2F5FA), PortfolioTheme.background],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                PortfolioNavigation(activeRoute: activeRoute),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 30, 22, 34),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: child,
                      ),
                    ),
                  ),
                ),
                const _PortfolioFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PortfolioNavigation extends StatelessWidget {
  const PortfolioNavigation({super.key, required this.activeRoute});

  final String activeRoute;

  static const items = [
    ('Home', '/', Icons.home_outlined),
    ('Skills', '/skills', Icons.auto_awesome_outlined),
    ('Projects', '/projects', Icons.grid_view_outlined),
    ('Social', '/social', Icons.connect_without_contact_outlined),
  ];

  void _navigate(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width > 1100;
    final compact = width <= 420;
    final showBrandName = width > 360;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: PortfolioTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .72)),
        boxShadow: PortfolioTheme.raisedShadows,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact
            ? 10
            : wide
            ? 40
            : width > 600
            ? 26
            : 18,
        vertical: wide
            ? 17
            : width > 600
            ? 14
            : 11,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _navigate(context, '/'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: compact ? 28 : 40,
                  height: compact ? 28 : 40,
                  fit: BoxFit.contain,
                ),
                if (showBrandName) ...[
                  SizedBox(width: compact ? 7 : 12),
                  Text(
                    'IRFANDEVS77',
                    style: TextStyle(
                      color: PortfolioTheme.text,
                      fontSize: compact ? 11 : 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: compact ? .5 : 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          if (wide)
            for (final (label, route, icon) in items)
              _NavLink(
                label: label,
                icon: icon,
                selected: activeRoute == route,
                onTap: () => _navigate(context, route),
              )
          else
            PopupMenuButton<String>(
              tooltip: 'Open navigation',
              icon: const Icon(Icons.menu, color: PortfolioTheme.text),
              color: PortfolioTheme.surfaceRaised,
              onSelected: (route) => _navigate(context, route),
              itemBuilder: (context) => [
                for (final (label, route, icon) in items)
                  PopupMenuItem(
                    value: route,
                    child: Row(
                      children: [
                        Icon(icon, color: PortfolioTheme.muted, size: 19),
                        const SizedBox(width: 12),
                        Text(label),
                      ],
                    ),
                  ),
              ],
            ),
          if (wide) ...[
            const SizedBox(width: 12),
            const PortfolioSearchButton(),
            const SizedBox(width: 8),
            const _AccountControl(),
          ] else ...[
            const PortfolioSearchButton(),
            const SizedBox(width: 4),
            const _AccountControl(compact: true),
          ],
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 7),
    child: TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? PortfolioTheme.cyan : PortfolioTheme.muted,
        backgroundColor: selected
            ? PortfolioTheme.surfaceRaised
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: selected ? 1 : 0,
        shadowColor: const Color(0x2673839A),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    ),
  );
}

class _AccountControl extends StatelessWidget {
  const _AccountControl({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) return _loginButton(context);
    return StreamBuilder<User?>(
      stream: FirebaseService.auth.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return _loginButton(context);
        }

        return PopupMenuButton<String>(
          tooltip: 'Account: ${user.email ?? 'signed in'}',
          color: PortfolioTheme.surfaceRaised,
          onSelected: (value) async {
            if (value == 'signout') {
              await FirebaseService.auth.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              }
              return;
            }
            final route = value == 'admin' ? '/admin' : '/';
            if (context.mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(route, (route) => route.isFirst);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              value: 'email',
              child: SizedBox(
                width: 190,
                child: Text(
                  user.email ?? 'Signed in',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: PortfolioTheme.muted),
                ),
              ),
            ),
            const PopupMenuItem(
              value: 'portfolio',
              child: _AccountMenuLabel(
                icon: Icons.home_outlined,
                label: 'irfandevs77',
              ),
            ),
            const PopupMenuItem(
              value: 'admin',
              child: _AccountMenuLabel(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin panel',
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'signout',
              child: _AccountMenuLabel(icon: Icons.logout, label: 'Sign out'),
            ),
          ],
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: PortfolioTheme.surfaceRaised,
              border: Border.all(color: Colors.white.withValues(alpha: .65)),
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xBFFFFFFF),
                  offset: Offset(-3, -3),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Color(0x1E73839A),
                  offset: Offset(3, 3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  color: PortfolioTheme.cyan,
                  size: 19,
                ),
                if (!compact) ...[
                  const SizedBox(width: 7),
                  const Text('Account', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  const Icon(Icons.expand_more, size: 16),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _loginButton(BuildContext context) => compact
      ? IconButton(
          tooltip: 'Sign in',
          onPressed: () => Navigator.of(context).pushNamed('/login'),
          style: IconButton.styleFrom(foregroundColor: PortfolioTheme.cyan),
          icon: const Icon(Icons.account_circle_outlined),
        )
      : TextButton.icon(
          onPressed: () => Navigator.of(context).pushNamed('/login'),
          style: TextButton.styleFrom(
            foregroundColor: PortfolioTheme.text,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            side: const BorderSide(color: PortfolioTheme.border),
          ),
          icon: const Icon(Icons.login, size: 17),
          label: const Text('Login'),
        );
}

class _AccountMenuLabel extends StatelessWidget {
  const _AccountMenuLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [Icon(icon, size: 17), const SizedBox(width: 10), Text(label)],
  );
}

class _PortfolioFooter extends StatelessWidget {
  const _PortfolioFooter();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: PortfolioTheme.border)),
    ),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        const ManagedContentText(
          field: 'footer',
          fallback: '© 2026 Irfan · Designed and built with care',
          textAlign: TextAlign.center,
          style: TextStyle(color: PortfolioTheme.muted, fontSize: 11),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/admin/login'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: PortfolioTheme.muted,
          ),
          child: const Text('Admin', style: TextStyle(fontSize: 11)),
        ),
      ],
    ),
  );
}
