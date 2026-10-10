import 'package:cloud_firestore/cloud_firestore.dart';

class Repository {
  const Repository({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.isPublic,
    required this.updatedAt,
    this.updatedOn,
  });

  factory Repository.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Repository(
      id: document.id,
      name: _string(data['name'], document.id),
      description: _string(data['description'], ''),
      language: _string(data['language'], ''),
      isPublic: data['isPublic'] is bool ? data['isPublic'] as bool : true,
      updatedAt: _string(data['updatedAt'], 'Updated recently'),
      updatedOn: _dateTime(data['updatedOn']),
    );
  }

  final String id;
  final String name;
  final String description;
  final String language;
  final bool isPublic;
  final String updatedAt;
  final DateTime? updatedOn;

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'language': language,
    'isPublic': isPublic,
    'updatedAt': updatedAt,
  };

  static String _string(Object? value, String fallback) =>
      value is String ? value : fallback;

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
