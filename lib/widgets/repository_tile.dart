import 'package:flutter/material.dart';

import '../models/repository.dart';
import '../services/starred_repository_store.dart';
import '../theme/app_theme.dart';
import 'animated_entrance.dart';

class RepositoryTile extends StatefulWidget {
  const RepositoryTile({
    super.key,
    required this.repository,
    required this.index,
  });

  final Repository repository;
  final int index;

  @override
  State<RepositoryTile> createState() => _RepositoryTileState();
}

class _RepositoryTileState extends State<RepositoryTile> {
  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    return AnimatedEntrance(
      delay: Duration(milliseconds: 55 * widget.index),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        repository.name,
                        style: const TextStyle(
                          color: AppTheme.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _Badge(text: repository.isPublic ? 'Public' : 'Private'),
                    ],
                  ),
                  if (repository.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      repository.description,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (repository.language.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: _languageColor(repository.language),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              repository.language,
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      Text(
                        repository.updatedAt,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<Set<String>>(
              valueListenable: StarredRepositoryStore.ids,
              builder: (context, starredIds, _) => _StarButton(
                starred: starredIds.contains(repository.id),
                onPressed: () => StarredRepositoryStore.toggle(repository.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _languageColor(String language) {
    switch (language.toLowerCase()) {
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'javascript':
        return const Color(0xFFF1E05A);
      case 'python':
        return const Color(0xFF3572A5);
      default:
        return AppTheme.blue;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.canvas,
      border: Border.all(color: Colors.white.withValues(alpha: .7)),
      borderRadius: BorderRadius.circular(12),
      boxShadow: AppTheme.raisedShadows,
    ),
    child: Text(
      text,
      style: const TextStyle(color: AppTheme.muted, fontSize: 11),
    ),
  );
}

class _StarButton extends StatelessWidget {
  const _StarButton({required this.starred, required this.onPressed});

  final bool starred;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.ink,
        backgroundColor: AppTheme.canvas,
        side: const BorderSide(color: AppTheme.border),
        minimumSize: const Size(73, 29),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        visualDensity: VisualDensity.compact,
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          starred ? Icons.star : Icons.star_outline,
          key: ValueKey(starred),
          size: 15,
          color: starred ? const Color(0xFF9A6700) : AppTheme.muted,
        ),
      ),
      label: Text(starred ? 'Starred' : 'Star'),
    );
  }
}
