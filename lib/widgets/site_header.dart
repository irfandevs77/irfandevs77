import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class SiteHeader extends StatelessWidget {
  const SiteHeader({super.key, this.activeTab = 'Repositories'});

  final String activeTab;

  static const tabs = [
    ('Overview', Icons.menu_book_outlined),
    ('Repositories', Icons.storage_outlined),
    ('Projects', Icons.grid_view_outlined),
    ('Packages', Icons.inventory_2_outlined),
    ('Stars', Icons.star_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: AppTheme.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .7)),
        boxShadow: AppTheme.raisedShadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              child: Row(
                children: [
                  _HeaderIcon(icon: Icons.menu, tooltip: 'Open menu'),
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 29,
                    height: 29,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'irfandevs77',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const Spacer(),
                  if (MediaQuery.sizeOf(context).width > 620) ...[
                    SizedBox(
                      width: 230,
                      height: 32,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Type / to search',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.muted,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 17),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 33,
                          ),
                          contentPadding: EdgeInsets.zero,
                          fillColor: AppTheme.surfaceRaised,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                  ],
                  _HeaderIcon(icon: Icons.notifications_none, tooltip: 'Inbox'),
                  const SizedBox(width: 8),
                  _HeaderIcon(icon: Icons.add, tooltip: 'Create new'),
                ],
              ),
            ),
            StreamBuilder(
              stream: FirebaseService.watchRepositories(),
              builder: (context, snapshot) => SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: [
                    for (final (label, icon) in tabs)
                      _NavigationTab(
                        label: label,
                        icon: icon,
                        selected: activeTab == label,
                        count: label == 'Repositories'
                            ? snapshot.data?.docs.length ?? 0
                            : null,
                        onTap: () {
                          final route = switch (label) {
                            'Overview' => '/overview',
                            'Repositories' => '/',
                            'Projects' => '/projects',
                            'Packages' => '/packages',
                            'Stars' => '/stars',
                            _ => '/',
                          };
                          if (ModalRoute.of(context)?.settings.name != route) {
                            Navigator.of(context).pushReplacementNamed(route);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.border),
          ],
        ),
      ),
    );
  }
}

class _NavigationTab extends StatelessWidget {
  const _NavigationTab({
    required this.label,
    required this.icon,
    required this.selected,
    this.count,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? AppTheme.canvas : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected ? AppTheme.raisedShadows : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: AppTheme.ink,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.border.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count', style: const TextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 30,
        decoration: BoxDecoration(
          color: AppTheme.canvas,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppTheme.raisedShadows,
        ),
        child: Icon(icon, size: 17, color: AppTheme.ink),
      ),
    );
  }
}
