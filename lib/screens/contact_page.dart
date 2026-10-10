import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';
import '../widgets/portfolio_components.dart';
import '../widgets/portfolio_frame.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sendingMessage = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sendingMessage = true);
    try {
      await FirebaseService.submitContactMessage(
        name: _name.text.trim(),
        email: _email.text.trim(),
        subject: _subject.text.trim(),
        message: _message.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your message has been sent.')),
      );
      _name.clear();
      _email.clear();
      _subject.clear();
      _message.clear();
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not send your message: ${error.message ?? error.code}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PortfolioFrame(
      activeRoute: '/social',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            eyebrow: 'Find me online',
            title: 'Social',
            description: 'Connect with me on GitHub, Instagram, or WhatsApp—or send me a message using the form below.',
          ),
          const SizedBox(height: 25),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 760;
              final form = _ContactForm(
                formKey: _formKey,
                name: _name,
                email: _email,
                subject: _subject,
                message: _message,
                sendingMessage: _sendingMessage,
                onSubmit: _sendMessage,
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 4, child: _ContactDetails()),
                    const SizedBox(width: 18),
                    Expanded(flex: 6, child: form),
                  ],
                );
              }
              return Column(
                children: [
                  const _ContactDetails(),
                  const SizedBox(height: 16),
                  form,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContactDetails extends StatelessWidget {
  const _ContactDetails();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: Firebase.apps.isEmpty ? null : FirebaseService.watchSiteContent(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return PortfolioCard(
          child: Text(
            'Contact information could not be loaded: ${snapshot.error}',
            style: const TextStyle(color: Color(0xFFB42332)),
          ),
        );
      }
      final content = snapshot.data?.data() ?? const {};
      final email = _stringValue(
        content['contactEmail'],
        'irfandevs77@gmail.com',
      );
      final location = _stringValue(content['contactLocation'], 'India');
      final instagram = _stringValue(
        content['socialInstagram'],
        'https://instagram.com/irfandevs77',
      );
      final github = _stringValue(
        content['socialGithub'],
        'https://github.com/irfandevs77',
      );
      const whatsappNumber = '8755158760';
      return PortfolioCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Social links',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            _ContactMethod(
              icon: Icons.mail_outline,
              title: 'Email',
              value: email,
              onTap: () => openPortfolioLink(
                context,
                email.startsWith('mailto:') ? email : 'mailto:$email',
              ),
            ),
            _ContactMethod(
              icon: Icons.location_on_outlined,
              title: 'Location',
              value: location,
            ),
            _ContactMethod(
              icon: Icons.camera_alt_outlined,
              title: 'Instagram',
              value: instagram,
              onTap: () => openPortfolioLink(context, instagram),
            ),
            _ContactMethod(
              icon: Icons.code,
              title: 'GitHub',
              value: github,
              onTap: () => openPortfolioLink(context, github),
            ),
            _ContactMethod(
              icon: Icons.chat_outlined,
              title: 'WhatsApp',
              value: whatsappNumber,
              onTap: () =>
                  openPortfolioLink(context, 'https://wa.me/91$whatsappNumber'),
            ),
          ],
        ),
      );
    },
  );
}

String _stringValue(Object? value, String fallback) =>
    value is String && value.isNotEmpty ? value : fallback;

class _ContactMethod extends StatelessWidget {
  const _ContactMethod({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: PortfolioTheme.blue.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: PortfolioTheme.cyan),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PortfolioTheme.muted,
                    fontSize: 10,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ContactForm extends StatelessWidget {
  const _ContactForm({
    required this.formKey,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.sendingMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController subject;
  final TextEditingController message;
  final bool sendingMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => PortfolioCard(
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send a message',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final nameField = _ContactField(
                controller: name,
                label: 'Your name',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name.'
                    : null,
              );
              final emailField = _ContactField(
                controller: email,
                label: 'Your email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value.trim())
                    ? 'Enter a valid email.'
                    : null,
              );
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [nameField, const SizedBox(height: 12), emailField],
                );
              }
              return Row(
                children: [
                  Expanded(child: nameField),
                  const SizedBox(width: 12),
                  Expanded(child: emailField),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _ContactField(controller: subject, label: 'Subject'),
          const SizedBox(height: 12),
          _ContactField(
            controller: message,
            label: 'Your message',
            maxLines: 5,
            validator: (value) => value == null || value.trim().length < 10
                ? 'Please write at least 10 characters.'
                : null,
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: sendingMessage ? 'Sending…' : 'Send message',
              icon: sendingMessage ? Icons.hourglass_top : Icons.send_outlined,
              onPressed: sendingMessage ? () {} : onSubmit,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your message is sent securely and can be managed from the admin inbox.',
            style: TextStyle(color: PortfolioTheme.muted, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
  );
}
