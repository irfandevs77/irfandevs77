import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FirebaseSetupPage extends StatelessWidget {
  const FirebaseSetupPage({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              elevation: 3,
              shadowColor: const Color(0x2673839A),
              color: AppTheme.canvas,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0x66FFFFFF)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.cloud_outlined,
                      size: 34,
                      color: AppTheme.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connect your Firebase project',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Firebase is configured for project irfandevs77-d9520. If initialization failed, check that the Firebase web app is enabled and pass updated web-app settings with the dart-defines below.',
                      style: TextStyle(color: AppTheme.muted, height: 1.55),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      SelectableText(
                        'Firebase initialization error: $error',
                        style: const TextStyle(
                          color: Color(0xFFB42332),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'To override the Firebase web-app values:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const _CodeBlock(
                      text:
                          'flutter run -d chrome \\\n'
                          '  --dart-define=FIREBASE_API_KEY=<your-api-key> \\\n'
                          '  --dart-define=FIREBASE_APP_ID=<your-web-app-id> \\\n'
                          '  --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id>',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Also enable Email/Password in Firebase Authentication, create a Firestore database, and publish firestore.rules from the project root. See README.md for admin-role setup and deployment instructions.',
                      style: TextStyle(
                        color: AppTheme.muted,
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.canvas,
      border: Border.all(color: AppTheme.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: SelectableText(
      text,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.6,
      ),
    ),
  );
}
