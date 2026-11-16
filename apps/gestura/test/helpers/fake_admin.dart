import 'dart:async';

import 'package:gestura/features/admin/data/content_store.dart';
import 'package:gestura/features/admin/domain/admin_access.dart';
import 'package:gestura/features/admin/domain/content_doc.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';
import 'package:gestura/features/auth/domain/app_user.dart';

class FakeAdminAccess implements AdminAccess {
  new([Set<String>? admins]) : admins = admins ?? {'admin@gestura.app'};

  final Set<String> admins;

  @override
  Future<bool> isAdmin(AppUser? user) async =>
      user is MemberUser && user.emailVerified && admins.contains(user.email);
}

class FakeContentStore implements ContentStore {
  final Map<ContentKind, Map<String, Map<String, Object?>>> docs = {
    for (final kind in ContentKind.values) kind: {},
  };
  final _changes = StreamController<ContentKind>.broadcast();
  bool fail = false;
  bool failWatch = false;
  final List<String> calls = [];

  List<ContentDoc> _list(ContentKind kind) => [
    for (final MapEntry(:key, :value) in docs[kind]!.entries)
      ContentDoc(key, value),
  ];

  @override
  Stream<List<ContentDoc>> watch(ContentKind kind) async* {
    if (failWatch) throw Exception('offline');
    yield _list(kind);
    yield* _changes.stream.where((k) => k == kind).map((_) => _list(kind));
  }

  @override
  Future<bool> exists(ContentKind kind, String id) async {
    if (fail) throw Exception('offline');
    return docs[kind]!.containsKey(id);
  }

  @override
  Future<ContentDoc?> read(ContentKind kind, String id) async {
    if (fail) throw Exception('offline');
    final data = docs[kind]![id];
    return data == null ? null : ContentDoc(id, data);
  }

  @override
  Future<void> save(
    ContentKind kind,
    String id,
    Map<String, Object?> data,
  ) async {
    if (fail) throw Exception('offline');
    calls.add('save ${kind.collection}/$id');
    docs[kind]![id] = data;
    _changes.add(kind);
  }

  @override
  Future<void> delete(ContentKind kind, String id) async {
    if (fail) throw Exception('offline');
    calls.add('delete ${kind.collection}/$id');
    docs[kind]!.remove(id);
    _changes.add(kind);
  }
}

const Map<String, Object?> sampleSign = {
  'signLanguage': 'ase',
  'gloss': 'HELLO',
  'meaning': {'en': 'Hello', 'ar': 'مرحبًا'},
  'category': 'greetings',
  'video': 'media/hello.mp4',
  'thumbnail': 'media/hello.jpg',
  'durationMs': 2400,
  'source': {'name': 'Gestura', 'license': 'CC BY 4.0'},
  'published': true,
};
