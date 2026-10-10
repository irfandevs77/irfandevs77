import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';
import '../widgets/portfolio_components.dart';
import '../widgets/portfolio_frame.dart';

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PortfolioFrame(
      activeRoute: '/skills',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            eyebrow: 'What I work with',
            title: 'Technologies I Work With',
            description: 'Tools I use today and areas I am actively learning. Skill levels reflect my own learning journey.',
          ),
          const SizedBox(height: 28),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseService.watchSkills(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _SkillState(
                  icon: Icons.cloud_off_outlined,
                  message: 'Could not load skills: ${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final groups = <String, List<Map<String, dynamic>>>{};
              for (final document in snapshot.data!.docs) {
                final skill = document.data();
                final category = skill['category'] is String
                    ? skill['category'] as String
                    : 'Other';
                groups.putIfAbsent(category, () => []).add(skill);
              }
              if (groups.isEmpty) {
                return const _SkillState(
                  icon: Icons.auto_awesome_outlined,
                  message: 'Skills will appear here once they are published.',
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 930
                      ? 3
                      : constraints.maxWidth > 600
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 15) / columns;
                  final entries = groups.entries.toList();
                  return Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: [
                      for (var index = 0; index < entries.length; index++)
                        SizedBox(
                          width: width,
                          child: AnimatedReveal(
                            delay: index * 90,
                            child: _SkillGroup(
                              category: entries[index].key,
                              skills: entries[index].value,
                              color: _groupColor(index),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          const PortfolioCard(
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: PortfolioTheme.cyan,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I value steady progress over checklists—these areas grow as I build and learn.',
                    style: TextStyle(color: PortfolioTheme.muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _groupColor(int index) => switch (index % 3) {
  0 => PortfolioTheme.cyan,
  1 => PortfolioTheme.blue,
  _ => PortfolioTheme.purple,
};

class _SkillGroup extends StatelessWidget {
  const _SkillGroup({
    required this.category,
    required this.skills,
    required this.color,
  });

  final String category;
  final List<Map<String, dynamic>> skills;
  final Color color;

  @override
  Widget build(BuildContext context) => PortfolioCard(
    accent: color,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_categoryIcon(category), color: color, size: 23),
        const SizedBox(height: 12),
        Text(category, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 21),
        for (final skill in skills)
          _SkillProgress(
            name: skill['name'] is String ? skill['name'] as String : 'Skill',
            icon: skill['icon'] is String ? skill['icon'] as String : '',
            progress:
                ((skill['level'] is num
                        ? (skill['level'] as num).toDouble()
                        : 0)
                    .clamp(0, 100)) /
                100,
            color: color,
          ),
      ],
    ),
  );

  IconData _categoryIcon(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('framework') || normalized.contains('tool')) {
      return Icons.widgets_outlined;
    }
    if (normalized.contains('explor')) return Icons.auto_awesome_outlined;
    return Icons.code;
  }
}

class _SkillState extends StatelessWidget {
  const _SkillState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => PortfolioCard(
    child: Row(
      children: [
        Icon(icon, color: PortfolioTheme.cyan),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: PortfolioTheme.muted, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _SkillProgress extends StatelessWidget {
  const _SkillProgress({
    required this.name,
    required this.icon,
    required this.progress,
    required this.color,
  });

  final String name;
  final String icon;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      children: [
        Row(
          children: [
            _SkillIcon(value: icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 12))),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(color: PortfolioTheme.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: PortfolioTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SkillIcon extends StatelessWidget {
  const _SkillIcon({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          value,
          width: 17,
          height: 17,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Icon(_iconForName(value), size: 16, color: color),
        ),
      );
    }
    return Icon(_iconForName(value), size: 16, color: color);
  }

  IconData _iconForName(String name) => switch (name.toLowerCase()) {
    'web' => Icons.web_outlined,
    'widgets' => Icons.widgets_outlined,
    'cloud' => Icons.cloud_outlined,
    'terminal' => Icons.terminal,
    'auto_awesome' => Icons.auto_awesome_outlined,
    'palette' => Icons.palette_outlined,
    'architecture' => Icons.account_tree_outlined,
    _ => Icons.code,
  };
}
