import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/repository.dart';
import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';
import '../widgets/portfolio_components.dart';
import '../widgets/portfolio_frame.dart';

class GithubPage extends StatelessWidget {
  const GithubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PortfolioFrame(
      activeRoute: '/github',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            eyebrow: 'Code & collaboration',
            title: 'My GitHub Profile',
            description: 'Explore my public repositories and the projects I am building in the open.',
          ),
          const SizedBox(height: 22),
          const _GithubProfileCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Public repositories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () => openPortfolioLink(
                  context,
                  'https://github.com/irfandevs77',
                ),
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text('Open GitHub'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _LiveRepositories(),
        ],
      ),
    );
  }
}

class _GithubProfileCard extends StatelessWidget {
  const _GithubProfileCard();

  @override
  Widget build(BuildContext context) => PortfolioCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 540;
        final avatar = Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: PortfolioTheme.blue, width: 2),
            gradient: const LinearGradient(
              colors: [PortfolioTheme.blue, PortfolioTheme.purple],
            ),
          ),
          child: const Center(
            child: Text(
              'I',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        const identity = _GithubIdentity();
        return horizontal
            ? Row(
                children: [
                  avatar,
                  const SizedBox(width: 20),
                  const Expanded(child: identity),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [avatar, const SizedBox(height: 15), identity],
              );
      },
    ),
  );
}

class _GithubIdentity extends StatelessWidget {
  const _GithubIdentity();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Irfan',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const Text(
        '@irfandevs77',
        style: TextStyle(color: PortfolioTheme.muted, fontSize: 13),
      ),
      const SizedBox(height: 8),
      const Text(
        'Developer Enthusiast · AI & Computer Science Student',
        style: TextStyle(color: PortfolioTheme.muted, fontSize: 12),
      ),
      const SizedBox(height: 13),
      GradientButton(
        label: 'Follow on GitHub',
        icon: Icons.code,
        onPressed: () =>
            openPortfolioLink(context, 'https://github.com/irfandevs77'),
      ),
    ],
  );
}

class _LiveRepositories extends StatelessWidget {
  const _LiveRepositories();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.watchProfile(),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          return _GithubMessage(message: profileSnapshot.error.toString());
        }
        if (!profileSnapshot.hasData) {
          return const _LoadingRepositories();
        }
        final profileData = profileSnapshot.data!.data();
        final profile = profileData == null
            ? Profile.defaults()
            : Profile.fromMap(profileData);
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.watchRepositories(),
          builder: (context, repositorySnapshot) {
            if (repositorySnapshot.hasError) {
              return _GithubMessage(
                message: repositorySnapshot.error.toString(),
              );
            }
            if (!repositorySnapshot.hasData) {
              return const _LoadingRepositories();
            }
            final repositories = repositorySnapshot.data!.docs
                .map(Repository.fromDocument)
                .toList();
            if (repositories.isEmpty) {
              return const _GithubMessage(
                message: 'No public repositories have been added yet.',
                isInfo: true,
              );
            }
            return Column(
              children: [
                PortfolioCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: PortfolioTheme.cyan,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${profile.name} · ${repositories.length} public repositories',
                          style: const TextStyle(
                            color: PortfolioTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.wifi,
                        color: PortfolioTheme.green,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: PortfolioTheme.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                for (final repository in repositories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RepositoryCard(repository: repository),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RepositoryCard extends StatelessWidget {
  const _RepositoryCard({required this.repository});

  final Repository repository;

  @override
  Widget build(BuildContext context) => PortfolioCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 9,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              repository.name,
              style: const TextStyle(
                color: PortfolioTheme.blue,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: PortfolioTheme.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Public',
                style: TextStyle(color: PortfolioTheme.muted, fontSize: 10),
              ),
            ),
          ],
        ),
        if (repository.description.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            repository.description,
            style: const TextStyle(color: PortfolioTheme.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            if (repository.language.isNotEmpty) ...[
              const Icon(Icons.circle, size: 9, color: PortfolioTheme.cyan),
              const SizedBox(width: 6),
              Text(
                repository.language,
                style: const TextStyle(
                  color: PortfolioTheme.muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 16),
            ],
            const Icon(Icons.update, size: 13, color: PortfolioTheme.muted),
            const SizedBox(width: 5),
            Text(
              repository.updatedAt,
              style: const TextStyle(color: PortfolioTheme.muted, fontSize: 11),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Open on GitHub',
              onPressed: () => openPortfolioLink(
                context,
                'https://github.com/irfandevs77/${Uri.encodeComponent(repository.name)}',
              ),
              icon: const Icon(
                Icons.open_in_new,
                size: 17,
                color: PortfolioTheme.muted,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _LoadingRepositories extends StatelessWidget {
  const _LoadingRepositories();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(28),
    child: Center(child: CircularProgressIndicator(color: PortfolioTheme.cyan)),
  );
}

class _GithubMessage extends StatelessWidget {
  const _GithubMessage({required this.message, this.isInfo = false});

  final String message;
  final bool isInfo;

  @override
  Widget build(BuildContext context) => PortfolioCard(
    child: Row(
      children: [
        Icon(
          isInfo ? Icons.info_outline : Icons.cloud_off_outlined,
          color: isInfo ? PortfolioTheme.cyan : Colors.orangeAccent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: PortfolioTheme.muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
