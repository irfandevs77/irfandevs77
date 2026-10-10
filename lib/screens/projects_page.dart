import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';
import '../widgets/portfolio_components.dart';
import '../widgets/portfolio_frame.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) => PortfolioFrame(
    activeRoute: '/projects',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          eyebrow: 'Selected work',
          title: "What I've Built",
          description: 'A few projects, experiments, and ideas I have been working on. Each one is a chance to learn something new.',
        ),
        const SizedBox(height: 26),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.watchProjects(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ProjectMessage(
                'Could not load projects: ${snapshot.error}',
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final projects = snapshot.data!.docs;
            if (projects.isEmpty) {
              return const _ProjectMessage(
                'Published projects will appear here.',
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 600
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 15) / columns;
                return Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    for (var index = 0; index < projects.length; index++)
                      SizedBox(
                        width: width,
                        child: AnimatedReveal(
                          delay: index * 80,
                          child: _ProjectCard(project: projects[index].data()),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        PortfolioCard(
          child: Row(
            children: [
              const Icon(
                Icons.rocket_launch_outlined,
                color: PortfolioTheme.cyan,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'More experiments and source code live on GitHub.',
                  style: TextStyle(color: PortfolioTheme.muted, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/social'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('GitHub'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final Map<String, dynamic> project;

  @override
  Widget build(BuildContext context) {
    final title = project['name'] is String
        ? project['name'] as String
        : 'Project';
    final description = project['description'] is String
        ? project['description'] as String
        : '';
    final thumbnail = project['thumbnail'] is String
        ? project['thumbnail'] as String
        : '';
    final technologies = project['technologies'] is List
        ? (project['technologies'] as List).whereType<String>().toList()
        : const <String>[];
    final githubUrl = project['githubUrl'] is String
        ? project['githubUrl'] as String
        : '';
    final liveUrl = project['liveUrl'] is String
        ? project['liveUrl'] as String
        : '';
    const accent = PortfolioTheme.cyan;
    final card = PortfolioCard(
      padding: EdgeInsets.zero,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 125,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: .23),
                  PortfolioTheme.surfaceRaised,
                ],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: thumbnail.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.rocket_launch_outlined,
                      color: accent,
                      size: 44,
                    ),
                  )
                : Image.network(
                    thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: PortfolioTheme.muted,
                        size: 35,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PortfolioTheme.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: PortfolioTheme.muted,
                    height: 1.55,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in technologies)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accent.withValues(alpha: .2),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(color: accent, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if (githubUrl.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => openPortfolioLink(context, githubUrl),
                        icon: const Icon(Icons.code, size: 15),
                        label: const Text('Source code'),
                      ),
                    if (liveUrl.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => openPortfolioLink(context, liveUrl),
                        icon: const Icon(Icons.open_in_new, size: 15),
                        label: const Text('Live site'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (title.toLowerCase() != 'synora') return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          Navigator.of(context).pushNamed('/synora', arguments: githubUrl),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: card),
    );
  }
}

class _ProjectMessage extends StatelessWidget {
  const _ProjectMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => PortfolioCard(
    child: Text(
      message,
      style: const TextStyle(color: PortfolioTheme.muted, fontSize: 13),
    ),
  );
}
