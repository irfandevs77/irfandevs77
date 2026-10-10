import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../theme/portfolio_theme.dart';
import '../widgets/portfolio_components.dart';
import '../widgets/portfolio_frame.dart';

class SynoraDetailsPage extends StatefulWidget {
  const SynoraDetailsPage({super.key, required this.githubUrl});

  final String githubUrl;

  @override
  State<SynoraDetailsPage> createState() => _SynoraDetailsPageState();
}

class _SynoraDetailsPageState extends State<SynoraDetailsPage> {
  late Future<List<_ApkVersion>> _versions;

  @override
  void initState() {
    super.initState();
    _versions = _loadVersions();
  }

  Future<List<_ApkVersion>> _loadVersions() async {
    final uri = Uri.base.resolve('Synora/apks/versions.json');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw StateError(
        'APK versions could not be loaded (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('APK version list has an invalid format.');
    }

    return decoded.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('An APK version entry is invalid.');
      }
      final fileName = entry['fileName'];
      final apkFileName = entry['apkFileName'];
      final version = entry['version'];
      final sizeBytes = entry['sizeBytes'];
      final downloadBytes = entry['downloadBytes'];
      final updatedAt = entry['updatedAt'];
      if (fileName is! String ||
          !RegExp(
            r'^[A-Za-z0-9][A-Za-z0-9._ -]*\.zip$',
            caseSensitive: false,
          ).hasMatch(fileName) ||
          fileName.contains('..') ||
          apkFileName is! String ||
          !RegExp(
            r'^[A-Za-z0-9][A-Za-z0-9._ -]*\.apk$',
            caseSensitive: false,
          ).hasMatch(apkFileName) ||
          apkFileName.contains('..') ||
          version is! String ||
          sizeBytes is! num ||
          downloadBytes is! num ||
          updatedAt is! String ||
          DateTime.tryParse(updatedAt) == null) {
        throw const FormatException('An APK version entry has invalid fields.');
      }
      return _ApkVersion(
        fileName: fileName,
        apkFileName: apkFileName,
        version: version,
        sizeBytes: sizeBytes.toInt(),
        downloadBytes: downloadBytes.toInt(),
        updatedAt: DateTime.parse(updatedAt),
      );
    }).toList();
  }

  Future<void> _download(_ApkVersion version) async {
    final uri = Uri.base.resolve(
      '/Synora/apks/${Uri.encodeComponent(version.fileName)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download ${version.fileName}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PortfolioFrame(
    activeRoute: '/projects',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          eyebrow: 'Project details',
          title: 'Synora',
          description: 'A modern messaging and social platform focused on real-time communication and a clean user experience.',
        ),
        const SizedBox(height: 22),
        PortfolioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.phone_android_outlined,
                    color: PortfolioTheme.cyan,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Android app releases',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Download a ZIP version, extract it on your Android device, then open the APK and follow the install prompt.',
                style: TextStyle(
                  color: PortfolioTheme.muted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<_ApkVersion>>(
                future: _versions,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _VersionsMessage(
                      message: 'Could not load APK versions: ${snapshot.error}',
                      action: TextButton.icon(
                        onPressed: () =>
                            setState(() => _versions = _loadVersions()),
                        icon: const Icon(Icons.refresh, size: 17),
                        label: const Text('Try again'),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.isEmpty) {
                    return const _VersionsMessage(
                      message: 'No APK releases have been published yet. New versions will appear here after they are added to the Synora APK folder and the site is deployed.',
                    );
                  }

                  return Column(
                    children: [
                      for (final version in snapshot.data!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: PortfolioTheme.surfaceRaised,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .72),
                              ),
                              boxShadow: PortfolioTheme.raisedShadows,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.android,
                                  color: PortfolioTheme.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        version.version,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'APK ${_formatSize(version.sizeBytes)} · ZIP ${_formatSize(version.downloadBytes)} · ${_formatDate(version.updatedAt)}',
                                        style: const TextStyle(
                                          color: PortfolioTheme.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () => _download(version),
                                  icon: const Icon(
                                    Icons.download_outlined,
                                    size: 17,
                                  ),
                                  label: const Text('Download ZIP'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PortfolioCard(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Want to inspect the source code?',
                  style: TextStyle(color: PortfolioTheme.muted, fontSize: 13),
                ),
              ),
              GradientButton(
                label: 'Source code on GitHub',
                icon: Icons.code,
                onPressed: () async {
                  final uri = Uri.tryParse(widget.githubUrl);
                  if (uri == null ||
                      !await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open the GitHub source link.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ApkVersion {
  const _ApkVersion({
    required this.fileName,
    required this.apkFileName,
    required this.version,
    required this.sizeBytes,
    required this.downloadBytes,
    required this.updatedAt,
  });

  final String fileName;
  final String apkFileName;
  final String version;
  final int sizeBytes;
  final int downloadBytes;
  final DateTime updatedAt;
}

class _VersionsMessage extends StatelessWidget {
  const _VersionsMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        message,
        style: const TextStyle(
          color: PortfolioTheme.muted,
          fontSize: 13,
          height: 1.55,
        ),
      ),
      if (action != null) ...[const SizedBox(height: 8), action!],
    ],
  );
}

String _formatSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
