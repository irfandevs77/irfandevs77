import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../theme/app_theme.dart';
import 'portfolio_components.dart';

class ProfileSidebar extends StatelessWidget {
  const ProfileSidebar({
    super.key,
    required this.profile,
    this.onEdit,
    this.compact = false,
  });

  final Profile profile;
  final VoidCallback? onEdit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            width: compact ? 156 : 264,
            height: compact ? 156 : 264,
            child: ProfileAvatar(imageUrl: profile.avatarUrl),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          profile.name,
          style: TextStyle(
            fontSize: compact ? 22 : 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${profile.username} · ${profile.pronouns}',
          style: const TextStyle(color: AppTheme.muted, fontSize: 16),
        ),
        const SizedBox(height: 14),
        Text(profile.bio, style: const TextStyle(height: 1.55, fontSize: 14)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 34,
          child: OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              backgroundColor: AppTheme.canvas,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Edit profile',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 17),
        if (profile.location.isNotEmpty)
          _ProfileDetail(
            icon: Icons.location_on_outlined,
            text: profile.location,
          ),
        if (profile.email.isNotEmpty)
          _ProfileDetail(icon: Icons.mail_outline, text: profile.email),
        if (profile.website.isNotEmpty)
          _ProfileDetail(icon: Icons.link, text: profile.website, isLink: true),
        if (profile.resumeUrl.isNotEmpty)
          TextButton.icon(
            onPressed: () => openPortfolioLink(context, profile.resumeUrl),
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('View resume'),
          ),
        _ProfileDetail(
          icon: Icons.rocket_launch_outlined,
          text: profile.joined,
        ),
      ],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.imageUrl = ''});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: AppTheme.raisedShadows,
        ),
        clipBehavior: Clip.antiAlias,
        child: Hero(
          tag: 'portfolio-portrait',
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Image.asset('assets/images/dp.png', fit: BoxFit.cover),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.canvas,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: AppTheme.raisedShadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Hero(
        tag: 'portfolio-portrait',
        child: Image.asset(
          'assets/images/dp.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    required this.icon,
    required this.text,
    this.isLink = false,
  });

  final IconData icon;
  final String text;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isLink ? AppTheme.blue : AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
