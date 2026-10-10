import 'package:flutter/material.dart';

import '../theme/portfolio_theme.dart';
import '../widgets/portfolio_components.dart';
import '../widgets/portfolio_frame.dart';

class InstagramPage extends StatelessWidget {
  const InstagramPage({super.key});

  static const _photos = [
    (
      'https://images.unsplash.com/photo-1519608487953-e999c86e7455?auto=format&fit=crop&w=500&q=80',
      Icons.nights_stay_outlined,
    ),
    (
      'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=500&q=80',
      Icons.laptop_mac,
    ),
    (
      'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=500&q=80',
      Icons.palette_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PortfolioFrame(
      activeRoute: '/instagram',
      child: Column(
        children: [
          PortfolioCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth > 570;
                final identity = Column(
                  crossAxisAlignment: horizontal
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Follow My Journey',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A little of what I build, learn, and find inspiring.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: PortfolioTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 17),
                    GradientButton(
                      label: 'Follow @irfandevs77',
                      icon: Icons.camera_alt_outlined,
                      onPressed: () => openPortfolioLink(
                        context,
                        'https://instagram.com/irfandevs77',
                      ),
                    ),
                  ],
                );
                final avatar = Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF9CE34),
                        Color(0xFFEE2A7B),
                        Color(0xFF6228D7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PortfolioTheme.purple.withValues(alpha: .18),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundColor: PortfolioTheme.surface,
                      child: Text(
                        'I',
                        style: TextStyle(
                          color: PortfolioTheme.text,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
                return horizontal
                    ? Row(
                        children: [
                          avatar,
                          const SizedBox(width: 23),
                          Expanded(child: identity),
                        ],
                      )
                    : Column(
                        children: [
                          avatar,
                          const SizedBox(height: 15),
                          identity,
                        ],
                      );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'A FEW THINGS THAT INSPIRE ME',
            style: TextStyle(
              color: PortfolioTheme.muted,
              fontSize: 10,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 720 ? 3 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 13) / columns;
              return Wrap(
                spacing: 13,
                runSpacing: 13,
                children: [
                  for (final (url, icon) in _photos)
                    SizedBox(
                      width: width,
                      height: 210,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: PortfolioTheme.surfaceRaised,
                                child: Icon(
                                  icon,
                                  color: PortfolioTheme.cyan,
                                  size: 40,
                                ),
                              ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
