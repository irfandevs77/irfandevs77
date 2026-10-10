import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';

Future<void> openPortfolioLink(BuildContext context, String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No link is available yet.')));
    return;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('This link is invalid: $trimmed')));
    return;
  }

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open: $trimmed')));
    }
  }
}

class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    super.key,
    required this.child,
    this.delay = 0,
    this.offset = 20,
    this.duration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final int delay;
  final double offset;
  final Duration duration;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, widget.offset / 60),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_controller);
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? widget.child
      : FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _offsetAnimation,
            child: widget.child,
          ),
        );
}

class PortfolioCard extends StatefulWidget {
  const PortfolioCard({
    super.key,
    required this.child,
    this.padding,
    this.accent,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accent;
  final double elevation;

  @override
  State<PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<PortfolioCard> {
  bool _hovered = false;

  bool _supportsHover(double width) {
    if (kIsWeb) return width >= 900;

    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final supportsHover = _supportsHover(constraints.maxWidth);
        return MouseRegion(
          onEnter: supportsHover
              ? (_) => setState(() => _hovered = true)
              : null,
          onExit: supportsHover
              ? (_) => setState(() => _hovered = false)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
            padding: widget.padding ?? const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: PortfolioTheme.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: _hovered ? .85 : .58),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: .88),
                  blurRadius: _hovered ? 22 : 18,
                  offset: const Offset(-7, -7),
                ),
                BoxShadow(
                  color: const Color(0x2673839A),
                  blurRadius: _hovered ? 22 : 18,
                  offset: Offset(7, widget.elevation > 0 ? 9 : 7),
                ),
                if (_hovered)
                  BoxShadow(
                    color: (widget.accent ?? PortfolioTheme.blue).withValues(
                      alpha: .12,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow.toUpperCase(),
        style: const TextStyle(
          color: PortfolioTheme.cyan,
          letterSpacing: 1.2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        style: const TextStyle(
          color: PortfolioTheme.text,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.08,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        description,
        style: const TextStyle(
          color: PortfolioTheme.muted,
          fontSize: 13,
          height: 1.6,
        ),
      ),
    ],
  );
}

class ManagedContentText extends StatelessWidget {
  const ManagedContentText({
    super.key,
    required this.field,
    required this.fallback,
    this.style,
    this.textAlign,
  });

  final String field;
  final String fallback;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return Text(fallback, style: style, textAlign: textAlign);
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.watchSiteContent(),
      builder: (context, snapshot) {
        final content = snapshot.data?.data() ?? const {};
        final value = content[field];
        final text = value is String && value.isNotEmpty ? value : fallback;
        return Text(text, style: style, textAlign: textAlign);
      },
    );
  }
}

class PageRouteButton extends StatelessWidget {
  const PageRouteButton({
    super.key,
    required this.label,
    required this.route,
    this.icon,
  });

  final String label;
  final String route;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final button = TextButton.icon(
      onPressed: () => Navigator.of(context).pushReplacementNamed(route),
      style: TextButton.styleFrom(
        backgroundColor: PortfolioTheme.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        elevation: 3,
        shadowColor: PortfolioTheme.blue.withValues(alpha: .25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(icon ?? Icons.arrow_forward, size: 17),
      label: Text(label),
    );
    return button;
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: PortfolioTheme.text,
          side: const BorderSide(color: PortfolioTheme.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: PortfolioTheme.blue,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: PortfolioTheme.blue.withValues(alpha: .25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 17),
        label: Text(label),
      ),
    );
  }
}

class ManagedIconLinkButton extends StatelessWidget {
  const ManagedIconLinkButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.field,
    required this.fallbackUrl,
  });

  final IconData icon;
  final String tooltip;
  final String field;
  final String fallbackUrl;

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return _buildButton(context, fallbackUrl);
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.watchSiteContent(),
      builder: (context, snapshot) {
        final content = snapshot.data?.data() ?? const {};
        final raw = content[field];
        final url = raw is String && raw.isNotEmpty ? raw : fallbackUrl;
        return _buildButton(context, url);
      },
    );
  }

  Widget _buildButton(BuildContext context, String url) => Tooltip(
    message: tooltip,
    child: IconButton(
      onPressed: () => openPortfolioLink(context, url),
      icon: Icon(icon, color: PortfolioTheme.text),
      style: IconButton.styleFrom(
        backgroundColor: PortfolioTheme.surfaceRaised,
        side: const BorderSide(color: PortfolioTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        elevation: 2,
        shadowColor: const Color(0x2673839A),
      ),
    ),
  );
}
