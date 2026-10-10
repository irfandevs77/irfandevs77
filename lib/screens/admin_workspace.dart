import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/repository.dart';
import '../services/firebase_service.dart';
import '../theme/portfolio_theme.dart';

class AdminWorkspace extends StatefulWidget {
  const AdminWorkspace({super.key});

  @override
  State<AdminWorkspace> createState() => _AdminWorkspaceState();
}

class _AdminWorkspaceState extends State<AdminWorkspace> {
  static const _sections = [
    ('Dashboard', Icons.space_dashboard_outlined),
    ('Profile', Icons.person_outline),
    ('Skills', Icons.auto_awesome_outlined),
    ('Projects', Icons.grid_view_outlined),
    ('GitHub', Icons.code),
    ('Website content', Icons.article_outlined),
    ('Appearance', Icons.palette_outlined),
    ('Messages', Icons.mail_outline),
    ('Security', Icons.shield_outlined),
  ];

  String _section = 'Dashboard';
  late Future<void> _initialContent;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _pronouns = TextEditingController();
  final _bio = TextEditingController();
  final _about = TextEditingController();
  final _location = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _joined = TextEditingController();
  final _avatarUrl = TextEditingController();
  final _resumeUrl = TextEditingController();
  bool _profileLoaded = false;
  bool _savingProfile = false;
  Future<int>? _visits;

  @override
  void initState() {
    super.initState();
    _initialContent = _loadProfile();
    _visits = FirebaseService.getWebsiteVisits();
  }

  Future<void> _loadProfile() async {
    await FirebaseService.seedInitialContent();
    final snapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc('public')
        .get();
    final profile = Profile.fromMap(snapshot.data() ?? const {});
    _name.text = profile.name;
    _username.text = profile.username;
    _pronouns.text = profile.pronouns;
    _bio.text = profile.bio;
    _about.text = profile.about;
    _location.text = profile.location;
    _email.text = profile.email;
    _website.text = profile.website;
    _joined.text = profile.joined;
    _avatarUrl.text = profile.avatarUrl;
    _resumeUrl.text = profile.resumeUrl;
    _profileLoaded = true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _username,
      _pronouns,
      _bio,
      _about,
      _location,
      _email,
      _website,
      _joined,
      _avatarUrl,
      _resumeUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      await FirebaseService.saveProfile(
        Profile(
          name: _name.text.trim(),
          username: _username.text.trim(),
          pronouns: _pronouns.text.trim(),
          bio: _bio.text.trim(),
          about: _about.text.trim(),
          location: _location.text.trim(),
          email: _email.text.trim(),
          website: _website.text.trim(),
          joined: _joined.text.trim(),
          avatarUrl: _avatarUrl.text.trim(),
          resumeUrl: _resumeUrl.text.trim(),
        ),
      );
      final user = FirebaseService.auth.currentUser;
      if (user != null) {
        await FirebaseService.recordAdminActivity(
          action: 'Updated profile details',
          user: user,
        );
      }
      _showMessage('Profile updated.');
    } on FirebaseException catch (error) {
      _showMessage('Could not save profile: ${error.message ?? error.code}');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _uploadProfileFile({
    required bool image,
    required TextEditingController target,
  }) async {
    try {
      final file = await FilePicker.pickFile(
        type: image ? FileType.image : FileType.custom,
        allowedExtensions: image ? null : const ['pdf'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final extension = file.extension?.toLowerCase() ?? '';
      final contentType = image
          ? (file.xFile.mimeType ?? 'image/$extension')
          : 'application/pdf';
      final reference = FirebaseStorage.instance.ref(
        'site/${image ? 'profile' : 'resume'}-${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      final resultSnapshot = await reference.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      final url = await resultSnapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() => target.text = url);
      _showMessage(image ? 'Profile photo uploaded.' : 'Resume uploaded.');
    } on FirebaseException catch (error) {
      _showMessage('Upload failed: ${error.message ?? error.code}');
    } catch (error) {
      _showMessage('Upload failed: $error');
    }
  }

  Future<void> _signOut() async {
    final user = FirebaseService.auth.currentUser;
    try {
      if (user != null) {
        await FirebaseService.recordAdminActivity(
          action: 'Signed out',
          user: user,
        );
      }
      await FirebaseService.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } on FirebaseException catch (error) {
      _showMessage(
        'Could not sign out cleanly: ${error.message ?? error.code}',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: PortfolioTheme.light,
    child: Scaffold(
      backgroundColor: PortfolioTheme.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F5FA), PortfolioTheme.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _AdminTopBar(onSignOut: _signOut),
              Expanded(
                child: FutureBuilder<void>(
                  future: _initialContent,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _LoadError(
                        message: snapshot.error.toString(),
                        onRetry: () => setState(() {
                          _profileLoaded = false;
                          _initialContent = _loadProfile();
                        }),
                      );
                    }
                    if (!_profileLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 900;
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1360),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: wide ? 28 : 16,
                                vertical: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _PageHeading(section: _section),
                                  const SizedBox(height: 20),
                                  if (wide)
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 225,
                                            child: _AdminNavigation(
                                              selected: _section,
                                              onSelect: (section) => setState(
                                                () => _section = section,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(child: _buildSection()),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    _CompactNavigation(
                                      selected: _section,
                                      onSelect: (section) =>
                                          setState(() => _section = section),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(child: _buildSection()),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildSection() {
    switch (_section) {
      case 'Dashboard':
        return _DashboardSection(
          visits: _visits,
          onRefreshVisits: () =>
              setState(() => _visits = FirebaseService.getWebsiteVisits()),
          onNavigate: (section) => setState(() => _section = section),
        );
      case 'Profile':
        return _buildProfileSection();
      case 'Skills':
        return _FirestoreCollectionSection(kind: _CollectionKind.skills);
      case 'Projects':
        return _FirestoreCollectionSection(kind: _CollectionKind.projects);
      case 'GitHub':
        return const _GitHubSection();
      case 'Website content':
        return const _SettingsSection(kind: _SettingsKind.content);
      case 'Appearance':
        return const _SettingsSection(kind: _SettingsKind.appearance);
      case 'Messages':
        return const _MessagesSection();
      case 'Security':
        return const _SecuritySection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfileSection() => SingleChildScrollView(
    child: _Panel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Profile',
              detail: 'Update the details shown across your website.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: PortfolioTheme.surfaceRaised,
                  backgroundImage: _avatarUrl.text.isEmpty
                      ? null
                      : NetworkImage(_avatarUrl.text),
                  child: _avatarUrl.text.isEmpty
                      ? const Icon(
                          Icons.person_outline,
                          color: PortfolioTheme.cyan,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _AdminTextField(
                    controller: _avatarUrl,
                    label: 'Profile photo URL',
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      _uploadProfileFile(image: true, target: _avatarUrl),
                  icon: const Icon(Icons.upload_outlined, size: 17),
                  label: const Text('Upload'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ResponsiveFields(
              children: [
                _AdminTextField(controller: _name, label: 'Name'),
                _AdminTextField(controller: _username, label: 'Username'),
                _AdminTextField(
                  controller: _pronouns,
                  label: 'Pronouns',
                  requiredField: false,
                ),
                _AdminTextField(
                  controller: _location,
                  label: 'Location',
                  requiredField: false,
                ),
                _AdminTextField(
                  controller: _bio,
                  label: 'Short bio',
                  maxLines: 2,
                ),
                _AdminTextField(
                  controller: _about,
                  label: 'About me',
                  maxLines: 5,
                  requiredField: false,
                ),
                _AdminTextField(
                  controller: _email,
                  label: 'Contact email',
                  keyboardType: TextInputType.emailAddress,
                  requiredField: false,
                ),
                _AdminTextField(
                  controller: _website,
                  label: 'Website / social link',
                  keyboardType: TextInputType.url,
                  requiredField: false,
                ),
                _AdminTextField(
                  controller: _joined,
                  label: 'Joined label',
                  requiredField: false,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AdminTextField(
                    controller: _resumeUrl,
                    label: 'Resume PDF URL',
                    requiredField: false,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      _uploadProfileFile(image: false, target: _resumeUrl),
                  icon: const Icon(Icons.upload_file_outlined, size: 17),
                  label: const Text('Upload PDF'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _savingProfile ? null : _saveProfile,
              icon: _savingProfile
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 17),
              label: const Text('Save profile'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: PortfolioTheme.background,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      border: Border(bottom: BorderSide(color: PortfolioTheme.border)),
      boxShadow: PortfolioTheme.raisedShadows,
    ),
    child: Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 36,
          height: 36,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IRFANDEVS77',
              style: TextStyle(
                color: PortfolioTheme.text,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 13,
              ),
            ),
            Text(
              'IRFANDEVS77 ADMIN',
              style: TextStyle(
                color: PortfolioTheme.muted,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('View site'),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_outlined),
        ),
      ],
    ),
  );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.section});

  final String section;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            const Text(
              'A calm workspace to manage your website.',
              style: TextStyle(color: PortfolioTheme.muted, fontSize: 13),
            ),
          ],
        ),
      ),
      const _OnlineBadge(),
    ],
  );
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: PortfolioTheme.green.withValues(alpha: .08),
      border: Border.all(color: PortfolioTheme.green.withValues(alpha: .25)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: PortfolioTheme.green, size: 7),
        SizedBox(width: 7),
        Text(
          'Admin access verified',
          style: TextStyle(color: PortfolioTheme.green, fontSize: 11),
        ),
      ],
    ),
  );
}

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  static const _items = _AdminWorkspaceState._sections;

  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        for (final (label, icon) in _items)
          _NavigationItem(
            label: label,
            icon: icon,
            selected: label == selected,
            onTap: () => onSelect(label),
          ),
      ],
    ),
  );
}

class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  static const _items = _AdminWorkspaceState._sections;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final (label, icon) = _items[index];
        final isSelected = label == selected;
        return OutlinedButton.icon(
          onPressed: () => onSelect(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: isSelected
                ? PortfolioTheme.cyan
                : PortfolioTheme.muted,
            backgroundColor: isSelected
                ? PortfolioTheme.blue.withValues(alpha: .12)
                : PortfolioTheme.surface,
            side: BorderSide(
              color: isSelected ? PortfolioTheme.blue : PortfolioTheme.border,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          ),
          icon: Icon(icon, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 12)),
        );
      },
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Material(
      color: selected
          ? PortfolioTheme.blue.withValues(alpha: .12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? PortfolioTheme.cyan : PortfolioTheme.muted,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? PortfolioTheme.text
                        : PortfolioTheme.muted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: PortfolioTheme.cyan,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.visits,
    required this.onRefreshVisits,
    required this.onNavigate,
  });

  final Future<int>? visits;
  final VoidCallback onRefreshVisits;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 760 ? 4 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: _CountMetric(
                    title: 'Total projects',
                    icon: Icons.grid_view_outlined,
                    color: PortfolioTheme.blue,
                    stream: FirebaseService.watchAllProjects(),
                    onTap: () => onNavigate('Projects'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _CountMetric(
                    title: 'Total skills',
                    icon: Icons.auto_awesome_outlined,
                    color: PortfolioTheme.purple,
                    stream: FirebaseService.watchAllSkills(),
                    onTap: () => onNavigate('Skills'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _CountMetric(
                    title: 'GitHub projects',
                    icon: Icons.code,
                    color: PortfolioTheme.cyan,
                    stream: FirebaseService.watchAllRepositories(),
                    onTap: () => onNavigate('GitHub'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _VisitMetric(
                    visits: visits,
                    onRefresh: onRefreshVisits,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Recent changes',
                detail: 'The latest updates made in this admin panel.',
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseService.watchAdminActivity(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _InlineError(message: snapshot.error.toString());
                  }
                  if (!snapshot.hasData) {
                    return const _LoadingInline();
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.history,
                      title: 'No changes yet',
                      detail: 'Your edits and sign-in activity will show here.',
                    );
                  }
                  return Column(
                    children: [
                      for (final doc in docs.take(8))
                        _ActivityRow(data: doc.data()),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CountMetric extends StatelessWidget {
  const _CountMetric({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) => _MetricCard(
          title: title,
          icon: icon,
          color: color,
          value: snapshot.hasError
              ? '—'
              : snapshot.hasData
              ? '${snapshot.data!.size}'
              : '…',
          onTap: onTap,
        ),
      );
}

class _VisitMetric extends StatelessWidget {
  const _VisitMetric({required this.visits, required this.onRefresh});

  final Future<int>? visits;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => FutureBuilder<int>(
    future: visits,
    builder: (context, snapshot) => _MetricCard(
      title: 'Website visits',
      icon: Icons.visibility_outlined,
      color: PortfolioTheme.green,
      value: snapshot.hasError
          ? 'Not set up'
          : snapshot.hasData
          ? _formatCount(snapshot.data!)
          : '…',
      tooltip: snapshot.hasError ? snapshot.error.toString() : null,
      onTap: onRefresh,
    ),
  );

  String _formatCount(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      if (index > 0 && (text.length - index) % 3 == 0) buffer.write(',');
      buffer.write(text[index]);
    }
    return buffer.toString();
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.onTap,
    this.tooltip,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String value;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? title,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: _Panel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_outward,
                  color: PortfolioTheme.muted,
                  size: 15,
                ),
              ],
            ),
            const SizedBox(height: 17),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PortfolioTheme.text,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: PortfolioTheme.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final timestamp = data['createdOn'];
    final date = timestamp is Timestamp ? timestamp.toDate() : null;
    final when = date == null
        ? 'Just now'
        : '${date.toLocal().year}-${date.toLocal().month.toString().padLeft(2, '0')}-${date.toLocal().day.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const CircleAvatar(
        radius: 17,
        backgroundColor: PortfolioTheme.surfaceRaised,
        child: Icon(
          Icons.check_circle_outline,
          color: PortfolioTheme.cyan,
          size: 17,
        ),
      ),
      title: Text(
        data['action'] is String ? data['action'] as String : 'Admin update',
        style: const TextStyle(fontSize: 12),
      ),
      subtitle: Text(
        data['email'] is String ? data['email'] as String : '',
        style: const TextStyle(color: PortfolioTheme.muted, fontSize: 10),
      ),
      trailing: Text(
        when,
        style: const TextStyle(color: PortfolioTheme.muted, fontSize: 10),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: PortfolioTheme.surface.withValues(alpha: .96),
      border: Border.all(color: PortfolioTheme.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: PortfolioTheme.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        detail,
        style: const TextStyle(color: PortfolioTheme.muted, fontSize: 11),
      ),
    ],
  );
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 700 ? 2 : 1;
      final width = columns == 1
          ? constraints.maxWidth
          : (constraints.maxWidth - 14) / 2;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _AdminTextField extends StatelessWidget {
  const _AdminTextField({
    required this.controller,
    required this.label,
    this.requiredField = true,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: const TextStyle(color: PortfolioTheme.text, fontSize: 13),
    decoration: InputDecoration(labelText: label),
    validator: !requiredField
        ? null
        : (value) => value == null || value.trim().isEmpty
              ? '$label is required.'
              : null,
  );
}

class _LoadingInline extends StatelessWidget {
  const _LoadingInline();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(20),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: _Panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: PortfolioTheme.purple),
            const SizedBox(height: 12),
            const Text('Could not load admin content'),
            const SizedBox(height: 8),
            SelectableText(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PortfolioTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: SelectableText(
      message,
      style: const TextStyle(color: Color(0xFFB42332), fontSize: 12),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(icon, color: PortfolioTheme.muted, size: 25),
        const SizedBox(height: 9),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: PortfolioTheme.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

enum _CollectionKind { skills, projects }

enum _SettingsKind { content, appearance }

class _FirestoreCollectionSection extends StatelessWidget {
  const _FirestoreCollectionSection({required this.kind});

  final _CollectionKind kind;

  String get title => kind == _CollectionKind.skills ? 'Skills' : 'Projects';
  String get collection =>
      kind == _CollectionKind.skills ? 'skills' : 'projects';

  @override
  Widget build(BuildContext context) {
    final stream = kind == _CollectionKind.skills
        ? FirebaseService.watchAllSkills()
        : FirebaseService.watchAllProjects();
    return Column(
      children: [
        _Panel(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Manage ${title.toLowerCase()} shown on your website.',
                  style: const TextStyle(
                    color: PortfolioTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add, size: 17),
                label: Text('Add $title'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _Panel(
                  child: _InlineError(message: snapshot.error.toString()),
                );
              }
              if (!snapshot.hasData) {
                return const _Panel(child: _LoadingInline());
              }
              final documents = snapshot.data!.docs;
              if (documents.isEmpty) {
                return _Panel(
                  child: _EmptyState(
                    icon: kind == _CollectionKind.skills
                        ? Icons.auto_awesome_outlined
                        : Icons.grid_view_outlined,
                    title: 'No ${title.toLowerCase()} yet',
                    detail: 'Add an item to start building this section.',
                  ),
                );
              }
              return _Panel(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  itemCount: documents.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: PortfolioTheme.border),
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final data = document.data();
                    return ListTile(
                      title: Text(
                        data['name'] is String
                            ? data['name'] as String
                            : document.id,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        _subtitle(data),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PortfolioTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') {
                            _edit(context, id: document.id, data: data);
                          } else {
                            _delete(context, document.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _subtitle(Map<String, dynamic> data) {
    if (kind == _CollectionKind.skills) {
      return '${data['category'] ?? 'Uncategorized'} · ${data['level'] ?? 0}%';
    }
    final technologies = data['technologies'];
    final detail = data['description'] is String
        ? data['description'] as String
        : '';
    final tags = technologies is List
        ? technologies.whereType<String>().join(' · ')
        : '';
    return [detail, tags].where((part) => part.isNotEmpty).join(' — ');
  }

  Future<void> _edit(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final result = await showDialog<_EditedDocument>(
      context: context,
      builder: (_) =>
          _DocumentEditorDialog(kind: kind, id: id, data: data ?? const {}),
    );
    if (result == null) return;
    try {
      if (kind == _CollectionKind.skills) {
        await FirebaseService.saveSkill(id: result.id, data: result.data);
      } else {
        await FirebaseService.saveProject(id: result.id, data: result.data);
      }
      final user = FirebaseService.auth.currentUser;
      if (user != null) {
        await FirebaseService.recordAdminActivity(
          action: '${id == null ? 'Added' : 'Updated'} ${title.toLowerCase()}',
          user: user,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$title saved.')));
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save $title: ${error.message}')),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${title.toLowerCase()} item?'),
        content: const Text('This item will be removed from the public site.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      if (kind == _CollectionKind.skills) {
        await FirebaseService.deleteSkill(id);
      } else {
        await FirebaseService.deleteProject(id);
      }
      final user = FirebaseService.auth.currentUser;
      if (user != null) {
        await FirebaseService.recordAdminActivity(
          action: 'Deleted ${title.toLowerCase()}',
          user: user,
        );
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete item: ${error.message}')),
        );
      }
    }
  }
}

class _EditedDocument {
  const _EditedDocument({required this.id, required this.data});

  final String id;
  final Map<String, Object?> data;
}

class _DocumentEditorDialog extends StatefulWidget {
  const _DocumentEditorDialog({
    required this.kind,
    required this.id,
    required this.data,
  });

  final _CollectionKind kind;
  final String? id;
  final Map<String, dynamic> data;

  @override
  State<_DocumentEditorDialog> createState() => _DocumentEditorDialogState();
}

class _DocumentEditorDialogState extends State<_DocumentEditorDialog> {
  late final Map<String, TextEditingController> _fields;
  late bool _isPublic;
  bool _saving = false;
  String? _error;

  bool get _isSkill => widget.kind == _CollectionKind.skills;

  @override
  void initState() {
    super.initState();
    final keys = _isSkill
        ? const ['name', 'category', 'level', 'icon']
        : const [
            'name',
            'description',
            'thumbnail',
            'technologies',
            'githubUrl',
            'liveUrl',
          ];
    _fields = {
      for (final key in keys)
        key: TextEditingController(
          text: key == 'technologies' && widget.data[key] is List
              ? (widget.data[key] as List).whereType<String>().join(', ')
              : widget.data[key]?.toString() ?? '',
        ),
    };
    _isPublic = widget.data['isPublic'] is bool
        ? widget.data['isPublic'] as bool
        : true;
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _fields['name']!.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final id = widget.id ?? _slug(name);
    final data = <String, Object?>{
      for (final entry in _fields.entries)
        entry.key: entry.key == 'technologies'
            ? entry.value.text
                  .split(',')
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toList()
            : entry.key == 'level'
            ? int.tryParse(entry.value.text.trim()) ?? 0
            : entry.value.text.trim(),
      'isPublic': _isPublic,
    };
    try {
      Navigator.of(context).pop(_EditedDocument(id: id, data: data));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _slug(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  @override
  Widget build(BuildContext context) {
    final labels = _isSkill
        ? const {
            'name': 'Skill name',
            'category': 'Category',
            'level': 'Level (0–100)',
            'icon': 'Icon name / URL',
          }
        : const {
            'name': 'Project name',
            'description': 'Description',
            'thumbnail': 'Thumbnail URL',
            'technologies': 'Technologies (comma separated)',
            'githubUrl': 'GitHub link',
            'liveUrl': 'Live website link',
          };
    return AlertDialog(
      title: Text(
        '${widget.id == null ? 'Add' : 'Edit'} ${_isSkill ? 'skill' : 'project'}',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in _fields.entries) ...[
                TextField(
                  controller: entry.value,
                  maxLines: entry.key == 'description' ? 3 : 1,
                  keyboardType: entry.key.endsWith('Url')
                      ? TextInputType.url
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: labels[entry.key]),
                ),
                const SizedBox(height: 12),
              ],
              if (!_isSkill)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show on public site'),
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
              if (_error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB42332)),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _GitHubSection extends StatefulWidget {
  const _GitHubSection();

  @override
  State<_GitHubSection> createState() => _GitHubSectionState();
}

class _GitHubSectionState extends State<_GitHubSection> {
  final _username = TextEditingController(text: 'irfandevs77');
  List<Repository> _fetched = [];
  Set<String> _selected = {};
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _loadRepositories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await FirebaseFirestore.instance
          .collection('site_meta')
          .doc('content')
          .get();
      final configuredUsername = content.data()?['githubUsername'];
      if (_username.text.trim() == 'irfandevs77' &&
          configuredUsername is String &&
          configuredUsername.isNotEmpty) {
        _username.text = configuredUsername;
      }
      final repositories = await FirebaseService.fetchGitHubRepositories(
        _username.text,
      );
      final current = await FirebaseFirestore.instance
          .collection('repositories')
          .get();
      final selected = current.docs
          .where((doc) => doc.data()['isPublic'] == true)
          .map((doc) => doc.id)
          .toSet();
      if (!mounted) return;
      setState(() {
        _fetched = repositories;
        _selected = selected.intersection(
          repositories.map((repository) => repository.id).toSet(),
        );
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSelection() async {
    try {
      await FirebaseService.saveSiteContent({
        'githubUsername': _username.text.trim(),
      });
      for (final repository in _fetched) {
        await FirebaseService.saveRepository(
          Repository(
            id: repository.id,
            name: repository.name,
            description: repository.description,
            language: repository.language,
            isPublic: _selected.contains(repository.id),
            updatedAt: repository.updatedAt,
          ),
        );
      }
      final user = FirebaseService.auth.currentUser;
      if (user != null) {
        await FirebaseService.recordAdminActivity(
          action: 'Updated GitHub repository selection',
          user: user,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GitHub selection saved.')),
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? error.code);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'GitHub repositories',
              detail: 'Load public repositories and choose which ones appear on your website.',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: 'GitHub username',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _loading ? null : _loadRepositories,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 17),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            if (_error != null) _InlineError(message: _error!),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: _Panel(
          padding: EdgeInsets.zero,
          child: _fetched.isEmpty
              ? const _EmptyState(
                  icon: Icons.code,
                  title: 'No repositories loaded',
                  detail: 'Enter a GitHub username and refresh the list.',
                )
              : ListView.separated(
                  itemCount: _fetched.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: PortfolioTheme.border),
                  itemBuilder: (context, index) {
                    final repository = _fetched[index];
                    return CheckboxListTile(
                      value: _selected.contains(repository.id),
                      activeColor: PortfolioTheme.blue,
                      title: Text(
                        repository.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        repository.description.isEmpty
                            ? repository.language
                            : repository.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PortfolioTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _selected.add(repository.id);
                        } else {
                          _selected.remove(repository.id);
                        }
                      }),
                    );
                  },
                ),
        ),
      ),
      if (_fetched.isNotEmpty) ...[
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saveSelection,
            icon: const Icon(Icons.save_outlined, size: 17),
            label: const Text('Save selection'),
          ),
        ),
      ],
    ],
  );
}

class _SettingsSection extends StatefulWidget {
  const _SettingsSection({required this.kind});

  final _SettingsKind kind;

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  late final Map<String, TextEditingController> _fields;
  String _themeMode = 'dark';
  String _accent = '#3C8DFF';
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  bool get _appearance => widget.kind == _SettingsKind.appearance;

  @override
  void initState() {
    super.initState();
    final labels = _appearance
        ? const ['logoUrl', 'faviconUrl', 'backgroundUrl']
        : const [
            'heroHeading',
            'heroDescription',
            'about',
            'socialGithub',
            'socialInstagram',
            'contactEmail',
            'contactLocation',
            'footer',
          ];
    _fields = {for (final label in labels) label: TextEditingController()};
    _load();
  }

  Future<void> _load() async {
    try {
      final reference = FirebaseFirestore.instance
          .collection('site_meta')
          .doc(_appearance ? 'appearance' : 'content');
      final snapshot = await reference.get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        for (final entry in _fields.entries) {
          entry.value.text = data[entry.key] is String
              ? data[entry.key] as String
              : '';
        }
        _themeMode = data['themeMode'] is String
            ? data['themeMode'] as String
            : 'dark';
        _accent = data['accent'] is String
            ? data['accent'] as String
            : '#3C8DFF';
        _loaded = true;
      });
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = error.message ?? error.code);
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = <String, Object?>{
        for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      };
      if (_appearance) {
        data['themeMode'] = _themeMode;
        data['accent'] = _accent;
        await FirebaseService.saveAppearance(data);
      } else {
        await FirebaseService.saveSiteContent(data);
      }
      final user = FirebaseService.auth.currentUser;
      if (user != null) {
        await FirebaseService.recordAdminActivity(
          action: _appearance
              ? 'Updated appearance settings'
              : 'Updated website content',
          user: user,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Settings saved.')));
      }
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _label(String key) => switch (key) {
    'heroHeading' => 'Hero heading',
    'heroDescription' => 'Hero description',
    'socialGithub' => 'GitHub URL',
    'socialInstagram' => 'Instagram URL',
    'contactEmail' => 'Contact email',
    'contactLocation' => 'Contact location',
    'logoUrl' => 'Website logo URL',
    'faviconUrl' => 'Favicon URL',
    'backgroundUrl' => 'Background image URL',
    'about' => 'About section',
    'footer' => 'Footer text',
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    if (!_loaded && _error == null) return const _LoadingInline();
    return SingleChildScrollView(
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: _appearance ? 'Appearance' : 'Website content',
              detail: _appearance
                  ? 'Choose your website color mode and brand assets.'
                  : 'Edit the text and links shown on your public pages.',
            ),
            if (_error != null) _InlineError(message: _error!),
            const SizedBox(height: 18),
            if (_appearance) ...[
              DropdownButtonFormField<String>(
                initialValue: _themeMode,
                decoration: const InputDecoration(labelText: 'Theme'),
                items: const [
                  DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _themeMode = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _accent,
                decoration: const InputDecoration(labelText: 'Accent color'),
                items: const [
                  DropdownMenuItem(value: '#3C8DFF', child: Text('Ocean blue')),
                  DropdownMenuItem(value: '#36D9E8', child: Text('Cyan')),
                  DropdownMenuItem(value: '#9B7BFF', child: Text('Violet')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _accent = value);
                },
              ),
              const SizedBox(height: 14),
            ],
            _ResponsiveFields(
              children: [
                for (final entry in _fields.entries)
                  _AdminTextField(
                    controller: entry.value,
                    label: _label(entry.key),
                    maxLines:
                        const [
                          'heroDescription',
                          'about',
                          'footer',
                        ].contains(entry.key)
                        ? 3
                        : 1,
                    requiredField: false,
                    keyboardType:
                        entry.key.toLowerCase().contains('url') ||
                            entry.key.startsWith('social')
                        ? TextInputType.url
                        : TextInputType.text,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined, size: 17),
              label: Text(_saving ? 'Saving…' : 'Save settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesSection extends StatelessWidget {
  const _MessagesSection();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseService.watchMessages(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _Panel(child: _InlineError(message: snapshot.error.toString()));
      }
      if (!snapshot.hasData) return const _Panel(child: _LoadingInline());
      final messages = snapshot.data!.docs;
      if (messages.isEmpty) {
        return const _Panel(
          child: _EmptyState(
            icon: Icons.mail_outline,
            title: 'Your inbox is empty',
            detail: 'Contact form messages will appear here.',
          ),
        );
      }
      return _Panel(
        padding: EdgeInsets.zero,
        child: ListView.separated(
          itemCount: messages.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: PortfolioTheme.border),
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data();
            final unread = data['read'] != true;
            final name = data['name'] is String ? data['name'] as String : '';
            final email = data['email'] is String
                ? data['email'] as String
                : '';
            final subject = data['subject'] is String
                ? data['subject'] as String
                : '';
            final body = data['message'] is String
                ? data['message'] as String
                : '';
            return ListTile(
              leading: Icon(
                unread
                    ? Icons.mark_email_unread_outlined
                    : Icons.drafts_outlined,
                color: unread ? PortfolioTheme.cyan : PortfolioTheme.muted,
              ),
              title: Text(
                subject.isEmpty ? name : '$name · $subject',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              subtitle: Text(
                '$email\n$body',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PortfolioTheme.muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (action) async {
                  try {
                    if (action == 'read') {
                      await FirebaseService.setMessageRead(doc.id, !unread);
                    } else {
                      await FirebaseService.deleteMessage(doc.id);
                    }
                  } on FirebaseException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not update message: ${error.message}',
                          ),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'read',
                    child: Text(unread ? 'Mark as read' : 'Mark as unread'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _SecuritySection extends StatefulWidget {
  const _SecuritySection();

  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  final _email = TextEditingController(
    text: FirebaseService.auth.currentUser?.email ?? '',
  );
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _changeEmail() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null || _email.text.trim().isEmpty) return;
    setState(() => _working = true);
    try {
      await user.verifyBeforeUpdateEmail(_email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your new email to verify the account change.'),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseService.auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    setState(() => _working = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPassword.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPassword.text);
      if (mounted) {
        _currentPassword.clear();
        _newPassword.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin password changed.')),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Admin account',
              detail: 'Update your sign-in email or password.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Admin email'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _working ? null : _changeEmail,
              child: const Text('Change admin email'),
            ),
            const Divider(height: 30, color: PortfolioTheme.border),
            TextField(
              controller: _currentPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed:
                  _working ||
                      _currentPassword.text.isEmpty ||
                      _newPassword.text.length < 6
                  ? null
                  : _changePassword,
              child: const Text('Change password'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Login activity',
              detail: 'Recent administrator sign-ins and account actions.',
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.watchAdminActivity(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _InlineError(message: snapshot.error.toString());
                }
                if (!snapshot.hasData) return const _LoadingInline();
                if (snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'No activity has been recorded yet.',
                    style: TextStyle(color: PortfolioTheme.muted, fontSize: 12),
                  );
                }
                return Column(
                  children: [
                    for (final doc in snapshot.data!.docs.take(10))
                      _ActivityRow(data: doc.data()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ],
  );
}
