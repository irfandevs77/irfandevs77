import 'dart:convert';

import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';

class PortfolioSearchButton extends StatelessWidget {
  const PortfolioSearchButton({super.key});

  static const _pages = [
    _SearchEntry(
      title: 'Home',
      type: 'Page',
      description: 'Portfolio home, introduction and featured highlights',
      route: '/',
    ),
    _SearchEntry(
      title: 'About',
      type: 'Page',
      description: 'About Irfan, computer science, AI, development and journey',
      route: '/',
    ),
    _SearchEntry(
      title: 'Skills',
      type: 'Page',
      description: 'Technologies, programming languages and tools',
      route: '/skills',
    ),
    _SearchEntry(
      title: 'Projects',
      type: 'Page',
      description: 'Apps, experiments, products and source code',
      route: '/projects',
    ),
    _SearchEntry(
      title: 'Synora',
      type: 'Project',
      description: 'Messaging app, Android APK versions, downloads and GitHub source code',
      route: '/synora',
    ),
    _SearchEntry(
      title: 'Social',
      type: 'Page',
      description:
          'GitHub, Instagram, WhatsApp 8755158760, email and contact form',
      route: '/social',
    ),
    _SearchEntry(
      title: 'GitHub',
      type: 'Social',
      description: 'GitHub profile and project source code',
      route: '/social',
    ),
    _SearchEntry(
      title: 'Instagram',
      type: 'Social',
      description: 'Instagram profile and social links',
      route: '/social',
    ),
    _SearchEntry(
      title: 'WhatsApp',
      type: 'Social',
      description: 'WhatsApp contact 8755158760',
      route: '/social',
    ),
    _SearchEntry(
      title: 'Contact',
      type: 'Page',
      description: 'Email, WhatsApp and send a message',
      route: '/social',
    ),
    _SearchEntry(
      title: 'Synora APK releases',
      type: 'Android app',
      description: 'Download APK versions and install Synora on Android',
      route: '/synora',
    ),
  ];

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _PortfolioSearchDialog(
        onSelect: (entry) {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pushNamed(entry.route);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () => _open(context),
    tooltip: 'Search the whole site',
    style: IconButton.styleFrom(
      foregroundColor: PortfolioTheme.text,
      backgroundColor: PortfolioTheme.surfaceRaised,
      elevation: 2,
      shadowColor: const Color(0x2673839A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    icon: const Icon(Icons.search),
  );
}

class _PortfolioSearchDialog extends StatefulWidget {
  const _PortfolioSearchDialog({required this.onSelect});

  final ValueChanged<_SearchEntry> onSelect;

  @override
  State<_PortfolioSearchDialog> createState() => _PortfolioSearchDialogState();
}

class _PortfolioSearchDialogState extends State<_PortfolioSearchDialog> {
  final _controller = TextEditingController();
  late final Future<List<_SearchEntry>> _content;

  @override
  void initState() {
    super.initState();
    _content = _loadContent();
  }

  Future<List<_SearchEntry>> _loadContent() async {
    final entries = <_SearchEntry>[];
    if (Firebase.apps.isNotEmpty) {
      final content = await FirebaseService.searchPublicContent();
      entries.addAll(
        content.map(
          (entry) => _SearchEntry(
            title: entry['title'] as String,
            type: entry['type'] as String,
            description: entry['searchableText'] as String,
            route: entry['route'] as String,
          ),
        ),
      );
    }

    if (kIsWeb) {
      final response = await http.get(
        Uri.base.resolve('Synora/apks/versions.json'),
      );
      if (response.statusCode != 200) {
        throw StateError(
          'APK versions could not be searched (${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('APK search data has an invalid format.');
      }
      for (final item in decoded) {
        if (item is! Map<String, dynamic> ||
            item['version'] is! String ||
            item['apkFileName'] is! String) {
          throw const FormatException('An APK search entry is invalid.');
        }
        entries.add(
          _SearchEntry(
            title: 'Synora ${item['version']}',
            type: 'Android app',
            description:
                'Synora APK download install Android ${item['apkFileName']}',
            route: '/synora',
          ),
        );
      }
    }
    return entries;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_SearchEntry> _filter(List<_SearchEntry> entries) {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final words = query.split(RegExp(r'\s+'));
    return entries
        .where((entry) {
          final content = '${entry.title} ${entry.type} ${entry.description}'
              .toLowerCase();
          return words.every(content.contains);
        })
        .take(30)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: PortfolioTheme.background,
      elevation: 16,
      shadowColor: const Color(0x2673839A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x66FFFFFF)),
      ),
      child: SizedBox(
        width: 580,
        height: size.height * .72,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search projects, skills, pages and more...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Close search',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<_SearchEntry>>(
                  future: _content,
                  builder: (context, snapshot) {
                    final entries = [
                      ...PortfolioSearchButton._pages,
                      ...?snapshot.data,
                    ];
                    final matches = _filter(entries);
                    if (_controller.text.trim().isEmpty) {
                      return const _SearchHint(
                        icon: Icons.travel_explore_outlined,
                        message: 'Search across projects, APK releases, skills, pages and social links.',
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        matches.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _SearchHint(
                        icon: Icons.cloud_off_outlined,
                        message:
                            'Some live project and skill data could not be searched: ${snapshot.error}',
                        matches: matches,
                        onSelect: widget.onSelect,
                      );
                    }
                    if (matches.isEmpty) {
                      return const _SearchHint(
                        icon: Icons.search_off_outlined,
                        message: 'No matching results. Try another keyword.',
                      );
                    }
                    return _SearchResults(
                      entries: matches,
                      onSelect: widget.onSelect,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search is case-insensitive; multiple words narrow the results.',
                style: TextStyle(color: PortfolioTheme.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.entries, required this.onSelect});

  final List<_SearchEntry> entries;
  final ValueChanged<_SearchEntry> onSelect;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: entries.length,
    separatorBuilder: (_, _) =>
        const Divider(height: 1, color: PortfolioTheme.border),
    itemBuilder: (context, index) {
      final entry = entries[index];
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: Icon(_iconFor(entry.type), color: PortfolioTheme.cyan),
        title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${entry.type} · ${entry.description}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: PortfolioTheme.muted, fontSize: 11),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: PortfolioTheme.muted,
        ),
        onTap: () => onSelect(entry),
      );
    },
  );
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({
    required this.icon,
    required this.message,
    this.matches = const [],
    this.onSelect,
  });

  final IconData icon;
  final String message;
  final List<_SearchEntry> matches;
  final ValueChanged<_SearchEntry>? onSelect;

  @override
  Widget build(BuildContext context) {
    if (matches.isNotEmpty && onSelect != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              message,
              style: const TextStyle(color: PortfolioTheme.muted, fontSize: 12),
            ),
          ),
          for (final entry in matches)
            ListTile(
              leading: Icon(_iconFor(entry.type), color: PortfolioTheme.cyan),
              title: Text(entry.title),
              subtitle: Text(
                '${entry.type} · ${entry.description}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSelect!(entry),
            ),
        ],
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: PortfolioTheme.cyan, size: 30),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PortfolioTheme.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEntry {
  const _SearchEntry({
    required this.title,
    required this.type,
    required this.description,
    required this.route,
  });

  final String title;
  final String type;
  final String description;
  final String route;
}

IconData _iconFor(String type) => switch (type) {
  'Project' || 'Android app' => Icons.rocket_launch_outlined,
  'Skill' => Icons.auto_awesome_outlined,
  'Repository' || 'Social' => Icons.code,
  _ => Icons.article_outlined,
};
