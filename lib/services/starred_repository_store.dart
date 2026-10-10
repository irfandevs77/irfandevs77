import 'package:flutter/foundation.dart';

abstract final class StarredRepositoryStore {
  static final ValueNotifier<Set<String>> ids = ValueNotifier({});

  static void toggle(String repositoryId) {
    final updated = Set<String>.of(ids.value);
    if (!updated.add(repositoryId)) {
      updated.remove(repositoryId);
    }
    ids.value = updated;
  }
}
