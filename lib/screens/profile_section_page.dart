import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/repository.dart';
import '../services/firebase_service.dart';
import '../services/starred_repository_store.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/profile_sidebar.dart';
import '../widgets/repository_tile.dart';
import '../widgets/site_header.dart';

class ProfileSectionPage extends StatelessWidget {
  const ProfileSectionPage({super.key, required this.section});

  final String section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(activeTab: section),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.watchProfile(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _SectionError(message: snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.data();
                final profile = data == null
                    ? Profile.defaults()
                    : Profile.fromMap(data);
                return _SectionLayout(section: section, profile: profile);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLayout extends StatelessWidget {
  const _SectionLayout({required this.section, required this.profile});

  final String section;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final sidebar = AnimatedEntrance(
          distance: .06,
          child: ProfileSidebar(
            profile: profile,
            compact: !wide,
            onEdit: () => Navigator.of(context).pushNamed('/admin/login'),
          ),
        );
        final body = _SectionBody(section: section, profile: profile);

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
                        SizedBox(width: 264, child: sidebar),
                        const SizedBox(width: 20),
                        Expanded(child: body),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 540),
                            child: sidebar,
                          ),
                        ),
                        const SizedBox(height: 28),
                        body,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.section, required this.profile});

  final String section;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case 'Overview':
        return _Overview(profile: profile);
      case 'Projects':
        return const _EmptySection(
          icon: Icons.grid_view_outlined,
          title: 'No public projects yet',
          message:
              'Public project boards will appear here when they are available.',
        );
      case 'Packages':
        return const _EmptySection(
          icon: Icons.inventory_2_outlined,
          title: 'No packages published',
          message: 'Packages published by this profile will be listed here.',
        );
      case 'Stars':
        return const _StarsSection();
      default:
        return const _EmptySection(
          icon: Icons.info_outline,
          title: 'Page not found',
          message: 'Choose a section from the profile navigation.',
        );
    }
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(
                profile.bio,
                style: const TextStyle(color: AppTheme.muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Pinned repositories',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              child: const Text('View all'),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.watchRepositories(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _SectionError(message: snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final repositories = snapshot.data!.docs
                .take(2)
                .map(Repository.fromDocument)
                .toList();
            if (repositories.isEmpty) {
              return const _Panel(
                child: Text(
                  'No repositories are available yet.',
                  style: TextStyle(color: AppTheme.muted),
                ),
              );
            }
            return Column(
              children: [
                for (var index = 0; index < repositories.length; index++)
                  RepositoryTile(
                    key: ValueKey(repositories[index].id),
                    repository: repositories[index],
                    index: index,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StarsSection extends StatelessWidget {
  const _StarsSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.watchRepositories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SectionError(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final repositories = snapshot.data!.docs
            .map(Repository.fromDocument)
            .toList();
        return ValueListenableBuilder<Set<String>>(
          valueListenable: StarredRepositoryStore.ids,
          builder: (context, starredIds, _) {
            final starred = repositories
                .where((repository) => starredIds.contains(repository.id))
                .toList();
            if (starred.isEmpty) {
              return const _EmptySection(
                icon: Icons.star_outline,
                title: 'No starred repositories',
                message: 'Star a repository from the Repositories page to see it here. Stars are kept for this visit.',
                actionLabel: 'Browse repositories',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Starred repositories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < starred.length; index++)
                  RepositoryTile(
                    key: ValueKey(starred[index].id),
                    repository: starred[index],
                    index: index,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel = 'Browse repositories',
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
        child: Column(
          children: [
            Icon(icon, size: 34, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.canvas,
      border: Border.all(color: Colors.white.withValues(alpha: .7)),
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppTheme.raisedShadows,
    ),
    child: child,
  );
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => _Panel(
    child: SelectableText(
      'Unable to load this section: $message',
      style: const TextStyle(color: Color(0xFFB42332)),
    ),
  );
}
