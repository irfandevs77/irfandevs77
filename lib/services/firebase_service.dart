import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import '../models/profile.dart';
import '../models/repository.dart';

class FirebaseService {
  FirebaseService._();

  static final _firestore = FirebaseFirestore.instance;
  static final auth = FirebaseAuth.instance;
  static final _profile = _firestore.collection('profiles').doc('public');
  static final _repositories = _firestore.collection('repositories');
  static final _siteSetup = _firestore.collection('site_meta').doc('setup');
  static final _siteContent = _firestore.collection('site_meta').doc('content');
  static final _appearance = _firestore
      .collection('site_meta')
      .doc('appearance');
  static final _skills = _firestore.collection('skills');
  static final _projects = _firestore.collection('projects');
  static final _messages = _firestore.collection('messages');
  static final _adminActivity = _firestore.collection('admin_activity');

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile() =>
      _profile.snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchRepositories() =>
      _repositories
          .where('isPublic', isEqualTo: true)
          .orderBy('name')
          .snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchAllRepositories() =>
      _repositories.orderBy('name').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchSkills() =>
      _skills.where('isPublic', isEqualTo: true).orderBy('name').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchProjects() =>
      _projects.where('isPublic', isEqualTo: true).orderBy('name').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchAllSkills() =>
      _skills.orderBy('name').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchAllProjects() =>
      _projects.orderBy('name').snapshots();

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchSiteContent() =>
      _siteContent.snapshots();

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchAppearance() =>
      _appearance.snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages() =>
      _messages.orderBy('createdOn', descending: true).snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchAdminActivity() =>
      _adminActivity
          .orderBy('createdOn', descending: true)
          .limit(30)
          .snapshots();

  static Future<List<Map<String, dynamic>>> searchPublicContent() async {
    final results = await Future.wait([
      _projects.where('isPublic', isEqualTo: true).get(),
      _skills.where('isPublic', isEqualTo: true).get(),
      _repositories.where('isPublic', isEqualTo: true).get(),
      _profile.get(),
      _siteContent.get(),
    ]);
    final entries = <Map<String, dynamic>>[];

    void addDocument(
      String type,
      String route,
      String id,
      Map<String, dynamic> data,
    ) {
      final searchableValues = <String>[id];
      for (final value in data.values) {
        if (value is String && value.trim().isNotEmpty) {
          searchableValues.add(value.trim());
        } else if (value is List) {
          searchableValues.addAll(
            value.whereType<String>().where((item) => item.trim().isNotEmpty),
          );
        }
      }
      final title = switch (type) {
        'Project' => data['name'],
        'Skill' => data['name'],
        'Repository' => data['name'],
        'Profile' => data['name'],
        _ => null,
      };
      entries.add({
        'type': type,
        'title': title is String && title.isNotEmpty ? title : id,
        'route': route,
        'searchableText': searchableValues.join(' '),
      });
    }

    final projects = results[0] as QuerySnapshot<Map<String, dynamic>>;
    for (final document in projects.docs) {
      final data = document.data();
      addDocument(
        'Project',
        document.id.toLowerCase() == 'synora' ? '/synora' : '/projects',
        document.id,
        data,
      );
    }

    final skills = results[1] as QuerySnapshot<Map<String, dynamic>>;
    for (final document in skills.docs) {
      addDocument('Skill', '/skills', document.id, document.data());
    }

    final repositories = results[2] as QuerySnapshot<Map<String, dynamic>>;
    for (final document in repositories.docs) {
      addDocument('Repository', '/social', document.id, document.data());
    }

    final profile = results[3] as DocumentSnapshot<Map<String, dynamic>>;
    if (profile.exists) {
      addDocument('Profile', '/', 'Profile', profile.data()!);
    }

    final siteContent = results[4] as DocumentSnapshot<Map<String, dynamic>>;
    if (siteContent.exists) {
      addDocument('Website content', '/', 'Website', siteContent.data()!);
    }

    return entries;
  }

  static Future<bool> hasAdminClaim(User user) async {
    final claims = await readClaims(user);
    return hasAdminRoleClaim(claims);
  }

  static Future<Map<String, dynamic>> readClaims(User user) async {
    final token = await user.getIdTokenResult(true);
    return token.claims ?? const <String, dynamic>{};
  }

  static bool hasAdminRoleClaim(Map<String, dynamic> claims) =>
      claims['admin'] == true;

  static Future<void> saveProfile(Profile profile) =>
      _profile.set(profile.toMap(), SetOptions(merge: true));

  static Future<void> saveRepository(Repository repository) {
    final data = repository.toMap()
      ..['updatedOn'] = FieldValue.serverTimestamp();
    return _repositories.doc(repository.id).set(data);
  }

  static Future<void> createRepository(Repository repository) async {
    final reference = _repositories.doc(repository.id);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw RepositoryAlreadyExistsException(repository.id);
      }
      final data = repository.toMap()
        ..['updatedOn'] = FieldValue.serverTimestamp();
      transaction.set(reference, data);
    });
  }

  static Future<void> deleteRepository(String id) =>
      _repositories.doc(id).delete();

  static Future<void> saveSkill({
    required String id,
    required Map<String, Object?> data,
  }) =>
      _skills.doc(id).set({...data, 'updatedOn': FieldValue.serverTimestamp()});

  static Future<void> deleteSkill(String id) => _skills.doc(id).delete();

  static Future<void> saveProject({
    required String id,
    required Map<String, Object?> data,
  }) => _projects.doc(id).set({
    ...data,
    'updatedOn': FieldValue.serverTimestamp(),
  });

  static Future<void> deleteProject(String id) => _projects.doc(id).delete();

  static Future<void> saveSiteContent(Map<String, Object?> data) =>
      _siteContent.set(data, SetOptions(merge: true));

  static Future<void> saveAppearance(Map<String, Object?> data) =>
      _appearance.set(data, SetOptions(merge: true));

  static Future<void> submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) => _messages.add({
    'name': name,
    'email': email,
    'subject': subject,
    'message': message,
    'read': false,
    'createdOn': FieldValue.serverTimestamp(),
  });

  static Future<void> setMessageRead(String id, bool read) =>
      _messages.doc(id).update({'read': read});

  static Future<void> deleteMessage(String id) => _messages.doc(id).delete();

  static Future<void> recordAdminActivity({
    required String action,
    required User user,
  }) => _adminActivity.add({
    'action': action,
    'email': user.email ?? '',
    'uid': user.uid,
    'createdOn': FieldValue.serverTimestamp(),
  });

  static Future<int> getWebsiteVisits() async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('getWebsiteVisits')
        .call<Map<String, dynamic>>();
    final visits = result.data['visits'];
    if (visits is! num) {
      throw StateError(
        'The analytics service returned an invalid visit count.',
      );
    }
    return visits.toInt();
  }

  static Future<List<Repository>> fetchGitHubRepositories(
    String username,
  ) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      throw ArgumentError.value(username, 'username', 'Must not be empty.');
    }
    final uri = Uri.https(
      'api.github.com',
      '/users/$normalizedUsername/repos',
      {'per_page': '100', 'sort': 'updated', 'type': 'owner'},
    );
    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );
    if (response.statusCode != 200) {
      throw StateError(
        'GitHub repository request failed (${response.statusCode}).',
      );
    }
    final body = jsonDecode(response.body);
    if (body is! List) {
      throw const FormatException('GitHub returned an unexpected response.');
    }
    return body.whereType<Map<String, dynamic>>().map((repository) {
      final name = repository['name'];
      final htmlUrl = repository['html_url'];
      if (name is! String || htmlUrl is! String) {
        throw const FormatException(
          'GitHub returned a repository without a name or URL.',
        );
      }
      return Repository(
        id: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]+'), '-'),
        name: name,
        description: repository['description'] is String
            ? repository['description'] as String
            : '',
        language: repository['language'] is String
            ? repository['language'] as String
            : '',
        isPublic: true,
        updatedAt: 'Updated recently',
      );
    }).toList();
  }

  static Future<void> seedInitialContent() async {
    final setup = await _siteSetup.get();
    final profile = await _profile.get();
    final repositories = await _repositories.limit(1).get();
    final skills = await _skills.limit(1).get();
    final projects = await _projects.limit(1).get();
    final content = await _siteContent.get();
    final appearance = await _appearance.get();
    final batch = _firestore.batch();

    if (!profile.exists) {
      batch.set(_profile, Profile.defaults().toMap());
    }
    if (repositories.docs.isEmpty &&
        !(setup.exists && setup.data()?['initialized'] == true)) {
      for (final repository in _defaultRepositories) {
        batch.set(_repositories.doc(repository.id), repository.toMap());
      }
    }
    if (skills.docs.isEmpty) {
      for (final skill in _defaultSkills) {
        batch.set(_skills.doc(skill['id']! as String), skill);
      }
    }
    if (projects.docs.isEmpty) {
      for (final project in _defaultProjects) {
        batch.set(_projects.doc(project['id']! as String), project);
      }
    }
    if (!content.exists) {
      batch.set(_siteContent, const {
        'heroHeading': 'Hi, I’m Irfan.',
        'heroDescription': 'Developer and computer science student, curious about AI and building useful things.',
        'about': 'I enjoy learning how technology works and using it to make useful things.',
        'socialGithub': 'https://github.com/irfandevs77',
        'socialInstagram': 'https://instagram.com/irfandevs77',
        'contactEmail': 'irfandevs77@gmail.com',
        'contactLocation': 'India',
        'footer': '© 2026 Irfan · Designed and built with care',
        'githubUsername': 'irfandevs77',
      });
    }
    if (!appearance.exists) {
      batch.set(_appearance, const {
        'themeMode': 'dark',
        'accent': '#3C8DFF',
        'logoUrl': '',
        'faviconUrl': '',
        'backgroundUrl': '',
      });
    }
    batch.set(_siteSetup, {'initialized': true});
    await batch.commit();
  }

  static final _defaultSkills = [
    for (final skill in [
      ('dart', 'Dart', 'Languages', 78, 'code'),
      ('python', 'Python', 'Languages', 70, 'code'),
      ('javascript', 'JavaScript', 'Languages', 66, 'code'),
      ('html-css', 'HTML & CSS', 'Languages', 75, 'web'),
      ('flutter', 'Flutter', 'Frameworks & tools', 78, 'widgets'),
      ('firebase', 'Firebase', 'Frameworks & tools', 66, 'cloud'),
      ('git-github', 'Git & GitHub', 'Frameworks & tools', 75, 'code'),
      ('vs-code', 'VS Code', 'Frameworks & tools', 84, 'terminal'),
      (
        'artificial-intelligence',
        'Artificial intelligence',
        'Currently exploring',
        54,
        'auto_awesome',
      ),
      ('ui-ux-design', 'UI / UX design', 'Currently exploring', 58, 'palette'),
      (
        'cloud-technologies',
        'Cloud technologies',
        'Currently exploring',
        46,
        'cloud',
      ),
      (
        'system-design',
        'System design',
        'Currently exploring',
        40,
        'architecture',
      ),
    ])
      {
        'id': skill.$1,
        'name': skill.$2,
        'category': skill.$3,
        'level': skill.$4,
        'icon': skill.$5,
        'isPublic': true,
      },
  ];

  static final _defaultProjects = [
    {
      'id': 'synora',
      'name': 'Synora',
      'description': 'A modern messaging and social platform concept focused on real-time communication and a clean user experience.',
      'thumbnail': '',
      'technologies': ['Flutter', 'Firebase', 'Real-time'],
      'githubUrl': 'https://github.com/irfandevs77',
      'liveUrl': '',
      'isPublic': true,
    },
    {
      'id': 'developer-portfolio',
      'name': 'Developer Portfolio',
      'description': 'A responsive portfolio website showcasing my profile, skills, projects, and ways to connect.',
      'thumbnail': '',
      'technologies': ['Flutter Web', 'Responsive UI', 'Animations'],
      'githubUrl': 'https://github.com/irfandevs77',
      'liveUrl': '',
      'isPublic': true,
    },
    {
      'id': 'ai-experiments',
      'name': 'AI Experiments',
      'description': 'A growing collection of learning projects exploring practical uses of AI and computer science.',
      'thumbnail': '',
      'technologies': ['Python', 'AI', 'Learning'],
      'githubUrl': 'https://github.com/irfandevs77',
      'liveUrl': '',
      'isPublic': true,
    },
  ];

  static const _defaultRepositories = [
    Repository(
      id: 'synora',
      name: 'synora',
      description: 'A modern messaging and social platform built for real-time communication.',
      language: 'Dart',
      isPublic: true,
      updatedAt: 'Updated just now',
    ),
    Repository(
      id: 'irfandevs77',
      name: 'irfandevs77',
      description: '',
      language: '',
      isPublic: true,
      updatedAt: 'Updated 43 minutes ago',
    ),
  ];
}

class RepositoryAlreadyExistsException implements Exception {
  const RepositoryAlreadyExistsException(this.id);

  final String id;

  @override
  String toString() => 'A repository with the URL slug "$id" already exists.';
}
