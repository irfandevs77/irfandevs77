import 'package:flutter/material.dart';

import 'about_page.dart';
import '../theme/portfolio_theme.dart';
import '../widgets/portfolio_components.dart';
import '../widgets/portfolio_frame.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PortfolioFrame(
      activeRoute: '/',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AnimatedReveal(child: _AvailabilityChip()),
              const SizedBox(height: 24),
              AnimatedReveal(
                delay: 80,
                child: ManagedContentText(
                  field: 'heroHeading',
                  fallback: 'Hi, I’m Irfan.',
                  style: TextStyle(
                    fontSize: 37,
                    height: 1.08,
                    letterSpacing: -1.1,
                    fontWeight: FontWeight.w700,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [
                          PortfolioTheme.cyan,
                          PortfolioTheme.blue,
                          PortfolioTheme.purple,
                        ],
                      ).createShader(const Rect.fromLTWH(0, 0, 380, 70)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const AnimatedReveal(
                delay: 160,
                child: Text(
                  'Developer · AI & Computer Science Student',
                  style: TextStyle(color: PortfolioTheme.muted, fontSize: 16),
                ),
              ),
              const SizedBox(height: 17),
              AnimatedReveal(
                delay: 200,
                child: const ManagedContentText(
                  field: 'heroDescription',
                  fallback: 'I build thoughtful digital experiences and practical products with clean code, creative ideas, and a curiosity for what comes next.',
                  style: TextStyle(
                    color: PortfolioTheme.text,
                    height: 1.7,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              AnimatedReveal(
                delay: 250,
                child: Wrap(
                  spacing: 11,
                  runSpacing: 10,
                  children: [
                    const PageRouteButton(
                      label: 'Explore my work',
                      route: '/projects',
                      icon: Icons.arrow_forward,
                    ),
                    GradientButton(
                      label: 'Connect with me',
                      outlined: true,
                      icon: Icons.connect_without_contact_outlined,
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/social'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 21),
              const AnimatedReveal(
                delay: 290,
                child: Row(
                  children: [
                    ManagedIconLinkButton(
                      icon: Icons.code,
                      tooltip: 'GitHub',
                      field: 'socialGithub',
                      fallbackUrl: 'https://github.com/irfandevs77',
                    ),
                    SizedBox(width: 9),
                    ManagedIconLinkButton(
                      icon: Icons.camera_alt_outlined,
                      tooltip: 'Instagram',
                      field: 'socialInstagram',
                      fallbackUrl: 'https://instagram.com/irfandevs77',
                    ),
                    SizedBox(width: 9),
                    ManagedIconLinkButton(
                      icon: Icons.mail_outline,
                      tooltip: 'Email',
                      field: 'contactEmail',
                      fallbackUrl: 'mailto:irfandevs77@gmail.com',
                    ),
                    SizedBox(width: 9),
                    ManagedIconLinkButton(
                      icon: Icons.chat_outlined,
                      tooltip: 'WhatsApp',
                      field: 'socialWhatsapp',
                      fallbackUrl: 'https://wa.me/918755158760',
                    ),
                  ],
                ),
              ),
            ],
          );
          final portrait = const AnimatedReveal(
            delay: 150,
            child: _HeroPortrait(),
          );

          return Column(
            children: [
              if (wide)
                Row(
                  children: [
                    Expanded(flex: 11, child: intro),
                    const SizedBox(width: 28),
                    Expanded(flex: 9, child: portrait),
                  ],
                )
              else
                Column(
                  children: [
                    intro,
                    const SizedBox(height: 26),
                    SizedBox(height: 320, child: portrait),
                  ],
                ),
              const SizedBox(height: 52),
              const _HomeHighlights(),
              const SizedBox(height: 56),
              const AboutSection(),
            ],
          );
        },
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: PortfolioTheme.green.withValues(alpha: .08),
      border: Border.all(color: PortfolioTheme.green.withValues(alpha: .3)),
      borderRadius: BorderRadius.circular(30),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: PortfolioTheme.green),
        SizedBox(width: 8),
        Text(
          'OPEN TO NEW OPPORTUNITIES',
          style: TextStyle(
            color: PortfolioTheme.green,
            fontSize: 10,
            letterSpacing: .8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _HeroPortrait extends StatelessWidget {
  const _HeroPortrait();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                PortfolioTheme.blue.withValues(alpha: .26),
                PortfolioTheme.purple.withValues(alpha: .08),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 255,
          height: 295,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(140),
            border: Border.all(
              color: PortfolioTheme.cyan.withValues(alpha: .35),
            ),
            boxShadow: [
              BoxShadow(
                color: PortfolioTheme.blue.withValues(alpha: .12),
                blurRadius: 38,
                spreadRadius: 3,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Hero(
            tag: 'portfolio-portrait',
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.06, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Image.asset(
                'assets/images/dp.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 38,
          child: _FloatBadge(
            icon: Icons.terminal,
            label: 'Building ideas',
            color: PortfolioTheme.cyan,
          ),
        ),
        Positioned(
          right: 5,
          top: 44,
          child: _FloatBadge(
            icon: Icons.auto_awesome,
            label: 'Always learning',
            color: PortfolioTheme.purple,
          ),
        ),
      ],
    );
  }
}

class _FloatBadge extends StatelessWidget {
  const _FloatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: PortfolioTheme.surfaceRaised,
      border: Border.all(color: PortfolioTheme.border),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.white, blurRadius: 16, offset: Offset(-4, -4)),
        BoxShadow(
          color: Color(0x2673839A),
          blurRadius: 16,
          offset: Offset(4, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _HomeHighlights extends StatelessWidget {
  const _HomeHighlights();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 700 ? 3 : 1;
      final items = [
        (
          Icons.lightbulb_outline,
          'Creative problem solver',
          'I enjoy turning ideas into useful, polished experiences.',
          PortfolioTheme.cyan,
        ),
        (
          Icons.code,
          'Building in public',
          'Explore the projects, experiments, and code I share.',
          PortfolioTheme.blue,
        ),
        (
          Icons.school_outlined,
          'Always curious',
          'Learning software engineering, AI, and new technologies.',
          PortfolioTheme.purple,
        ),
      ];
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final (icon, title, description, color) in items)
            SizedBox(
              width: columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 28) / 3,
              child: PortfolioCard(
                accent: color,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(height: 14),
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: PortfolioTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
