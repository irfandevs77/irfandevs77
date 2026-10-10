import 'package:flutter/material.dart';

import '../theme/portfolio_theme.dart';
import '../widgets/portfolio_components.dart';
import '../widgets/portfolio_frame.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PortfolioFrame(activeRoute: '/', child: const AboutSection());
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          eyebrow: 'A little about me',
          title: 'Who Am I?',
          description: 'A curious developer who enjoys learning how technology works and using it to make useful things.',
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;
            final about = PortfolioCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hey! I'm Irfan 👋",
                    style: TextStyle(
                      color: PortfolioTheme.text,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 13),
                  ManagedContentText(
                    field: 'about',
                    fallback: 'I am a developer and computer science student with a strong interest in AI, software, and creative problem solving. I like building projects from the first sketch to the final detail, and I believe the best way to learn is to stay curious and keep creating.',
                    style: const TextStyle(
                      color: PortfolioTheme.muted,
                      height: 1.8,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 18),
                  _FactRow(
                    icon: Icons.location_on_outlined,
                    label: 'Based in',
                    value: 'India',
                  ),
                  _FactRow(
                    icon: Icons.school_outlined,
                    label: 'Currently',
                    value: 'Studying computer science',
                  ),
                  _FactRow(
                    icon: Icons.favorite_border,
                    label: 'Interested in',
                    value: 'Development · AI · Design',
                  ),
                  _FactRow(
                    icon: Icons.language,
                    label: 'Languages',
                    value: 'English · Hindi',
                  ),
                ],
              ),
            );
            final journey = const PortfolioCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My journey',
                    style: TextStyle(
                      color: PortfolioTheme.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 18),
                  _JourneyStep(
                    number: '01',
                    title: 'Curiosity sparked',
                    description:
                        'Started exploring computers and how software is made.',
                    color: PortfolioTheme.cyan,
                  ),
                  _JourneyStep(
                    number: '02',
                    title: 'Learning by building',
                    description:
                        'Turning tutorials and ideas into hands-on projects.',
                    color: PortfolioTheme.blue,
                  ),
                  _JourneyStep(
                    number: '03',
                    title: 'Growing every day',
                    description: 'Exploring AI, better engineering, and new ways to create.',
                    color: PortfolioTheme.purple,
                  ),
                ],
              ),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: about),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: journey),
                ],
              );
            }
            return Column(
              children: [about, const SizedBox(height: 16), journey],
            );
          },
        ),
        const SizedBox(height: 20),
        const PortfolioCard(
          child: Row(
            children: [
              Icon(Icons.format_quote, color: PortfolioTheme.cyan, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stay curious. Keep building. Make every iteration a little better.',
                  style: TextStyle(
                    color: PortfolioTheme.text,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        Icon(icon, size: 17, color: PortfolioTheme.cyan),
        const SizedBox(width: 10),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(color: PortfolioTheme.muted, fontSize: 12),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.number,
    required this.title,
    required this.description,
    required this.color,
  });

  final String number;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withValues(alpha: .25)),
          ),
          child: Text(
            number,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
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
      ],
    ),
  );
}
