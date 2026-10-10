import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/repository.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/profile_sidebar.dart';
import '../widgets/repository_tile.dart';
import '../widgets/site_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _searchController = TextEditingController();
  String _search = '';
  String _type = 'All';
  String _language = 'All';
  String _sort = 'Recently updated';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SiteHeader(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.watchProfile(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.hasError) {
                  return _LoadError(
                    message: 'Could not load the profile.',
                    details: profileSnapshot.error.toString(),
                  );
                }
                if (!profileSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final profileData = profileSnapshot.data!.data();
                final profile = profileData == null
                    ? Profile.defaults()
                    : Profile.fromMap(profileData);

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseService.watchRepositories(),
                  builder: (context, repositorySnapshot) {
                    if (repositorySnapshot.hasError) {
                      return _LoadError(
                        message: 'Could not load the repositories.',
                        details: repositorySnapshot.error.toString(),
                      );
                    }
                    if (!repositorySnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final repositories = repositorySnapshot.data!.docs
                        .map(Repository.fromDocument)
                        .toList();
                    return _ProfileContent(
                      profile: profile,
                      repositories: repositories,
                      searchController: _searchController,
                      search: _search,
                      type: _type,
                      language: _language,
                      sort: _sort,
                      onSearchChanged: (value) =>
                          setState(() => _search = value),
                      onTypeChanged: (value) => setState(() => _type = value),
                      onLanguageChanged: (value) =>
                          setState(() => _language = value),
                      onSortChanged: (value) => setState(() => _sort = value),
                      onEditProfile: () =>
                          Navigator.of(context).pushNamed('/admin/login'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.repositories,
    required this.searchController,
    required this.search,
    required this.type,
    required this.language,
    required this.sort,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onLanguageChanged,
    required this.onSortChanged,
    required this.onEditProfile,
  });

  final Profile profile;
  final List<Repository> repositories;
  final TextEditingController searchController;
  final String search;
  final String type;
  final String language;
  final String sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final profile = AnimatedEntrance(
          distance: .06,
          child: ProfileSidebar(
            profile: this.profile,
            onEdit: onEditProfile,
            compact: !wide,
          ),
        );
        final content = _RepositoriesContent(
          repositories: repositories,
          searchController: searchController,
          search: search,
          type: type,
          language: language,
          sort: sort,
          onSearchChanged: onSearchChanged,
          onTypeChanged: onTypeChanged,
          onLanguageChanged: onLanguageChanged,
          onSortChanged: onSortChanged,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 24 : 18,
            vertical: wide ? 24 : 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 264, child: profile),
                        const SizedBox(width: 20),
                        Expanded(child: content),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 540),
                            child: profile,
                          ),
                        ),
                        const SizedBox(height: 28),
                        content,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _RepositoriesContent extends StatelessWidget {
  const _RepositoriesContent({
    required this.repositories,
    required this.searchController,
    required this.search,
    required this.type,
    required this.language,
    required this.sort,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onLanguageChanged,
    required this.onSortChanged,
  });

  final List<Repository> repositories;
  final TextEditingController searchController;
  final String search;
  final String type;
  final String language;
  final String sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final languages =
        repositories
            .map((repository) => repository.language)
            .where((language) => language.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final visibleRepositories =
        repositories.where((repository) {
          final matchesSearch =
              '${repository.name} ${repository.description} ${repository.language}'
                  .toLowerCase()
                  .contains(search.toLowerCase());
          final matchesType =
              type == 'All' || (type == 'Public' && repository.isPublic);
          final matchesLanguage =
              language == 'All' || repository.language == language;
          return matchesSearch && matchesType && matchesLanguage;
        }).toList()..sort((a, b) {
          if (sort == 'Name') {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          final first = a.updatedOn ?? DateTime.fromMillisecondsSinceEpoch(0);
          final second = b.updatedOn ?? DateTime.fromMillisecondsSinceEpoch(0);
          return second.compareTo(first);
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RepositoryToolbar(
          searchController: searchController,
          type: type,
          language: language,
          languages: languages,
          sort: sort,
          onSearchChanged: onSearchChanged,
          onTypeChanged: onTypeChanged,
          onLanguageChanged: onLanguageChanged,
          onSortChanged: onSortChanged,
        ),
        if (visibleRepositories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
            child: Column(
              children: [
                const Icon(Icons.search_off, size: 34, color: AppTheme.muted),
                const SizedBox(height: 12),
                Text(
                  repositories.isEmpty
                      ? 'No repositories yet.'
                      : 'No repositories match these filters.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.muted),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < visibleRepositories.length; index++)
            RepositoryTile(
              key: ValueKey(visibleRepositories[index].id),
              repository: visibleRepositories[index],
              index: index,
            ),
        const SizedBox(height: 28),
        const _SiteFooter(),
      ],
    );
  }
}

class _RepositoryToolbar extends StatelessWidget {
  const _RepositoryToolbar({
    required this.searchController,
    required this.type,
    required this.language,
    required this.languages,
    required this.sort,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onLanguageChanged,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final String type;
  final String language;
  final List<String> languages;
  final String sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 680) {
          return Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              _FilterButton(
                label: type == 'All' ? 'Type' : type,
                values: const ['All', 'Public'],
                selected: type,
                onSelected: onTypeChanged,
              ),
              const SizedBox(width: 8),
              _FilterButton(
                label: language == 'All' ? 'Language' : language,
                values: ['All', ...languages],
                selected: language,
                onSelected: onLanguageChanged,
              ),
              const SizedBox(width: 8),
              _FilterButton(
                label: sort == 'Recently updated' ? 'Sort' : sort,
                values: const ['Recently updated', 'Name'],
                selected: sort,
                onSelected: onSortChanged,
              ),
              const SizedBox(width: 8),
              _NewButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/admin/login');
                },
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 8,
              children: [
                _FilterButton(
                  label: type == 'All' ? 'Type' : type,
                  values: const ['All', 'Public'],
                  selected: type,
                  onSelected: onTypeChanged,
                ),
                _FilterButton(
                  label: language == 'All' ? 'Language' : language,
                  values: ['All', ...languages],
                  selected: language,
                  onSelected: onLanguageChanged,
                ),
                _FilterButton(
                  label: sort == 'Recently updated' ? 'Sort' : sort,
                  values: const ['Recently updated', 'Name'],
                  selected: sort,
                  onSelected: onSortChanged,
                ),
                _NewButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/admin/login');
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Find a repository...',
        prefixIcon: Icon(Icons.search, size: 17),
        prefixIconConstraints: BoxConstraints(minWidth: 35),
      ),
    ),
  );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: label,
    onSelected: onSelected,
    itemBuilder: (context) => [
      for (final value in values)
        PopupMenuItem<String>(
          value: value,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: selected == value
                    ? const Icon(Icons.check, size: 15)
                    : null,
              ),
              Text(value),
            ],
          ),
        ),
    ],
    child: _ButtonSurface(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    ),
  );
}

class _NewButton extends StatelessWidget {
  const _NewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppTheme.green,
      foregroundColor: Colors.white,
      minimumSize: const Size(76, 34),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      visualDensity: VisualDensity.compact,
    ),
    icon: const Icon(Icons.add, size: 15),
    label: const Text('New', style: TextStyle(fontSize: 13)),
  );
}

class _ButtonSurface extends StatelessWidget {
  const _ButtonSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: AppTheme.canvas,
      border: Border.all(color: Colors.white.withValues(alpha: .7)),
      borderRadius: BorderRadius.circular(12),
      boxShadow: AppTheme.raisedShadows,
    ),
    child: Center(
      child: DefaultTextStyle(
        style: const TextStyle(
          color: AppTheme.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    ),
  );
}

class _SiteFooter extends StatelessWidget {
  const _SiteFooter();

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 15,
    runSpacing: 8,
    children: [
      const Icon(Icons.code, size: 17, color: AppTheme.muted),
      const Text(
        '© 2026 · Irfan',
        style: TextStyle(color: AppTheme.muted, fontSize: 11),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pushNamed('/admin/login'),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Admin',
          style: TextStyle(color: AppTheme.muted, fontSize: 11),
        ),
      ),
    ],
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.details});

  final String message;
  final String details;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppTheme.muted,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              details,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
