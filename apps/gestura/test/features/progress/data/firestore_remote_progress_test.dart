import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/data/firestore_remote_progress.dart';
import 'package:gestura/features/progress/data/progress_documents.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura_core/gestura_core.dart';

final DateTime _completed = DateTime.utc(2026, 11, 9, 8);
final DateTime _updated = DateTime.utc(2026, 11, 10, 9);

LessonProgress _progress(String id, int score) => LessonProgress(
  lessonId: LessonId(id),
  bestScore: score,
  completedAt: _completed,
  updatedAt: _updated,
);

StoredDocument _stored(String id, int score) => (
  id: id,
  data: {
    'bestScore': score,
    'completedAt': Timestamp.fromDate(_completed),
    'updatedAt': Timestamp.fromDate(_updated),
  },
);

class _FakeDocuments implements ProgressDocuments {
  final Map<String, List<StoredDocument>> users = {};
  final List<int> writes = [];
  final List<int> deletes = [];
  FirebaseException? error;

  @override
  Future<List<StoredDocument>> read(String userId) async {
    if (error case final FirebaseException error) throw error;
    return users[userId] ?? const [];
  }

  @override
  Future<void> write(String userId, List<StoredDocument> documents) async {
    if (error case final FirebaseException error) throw error;
    writes.add(documents.length);
    users.putIfAbsent(userId, () => []).addAll(documents);
  }

  @override
  Future<void> delete(String userId, List<String> ids) async {
    deletes.add(ids.length);
    users[userId]?.removeWhere((document) => ids.contains(document.id));
  }
}

void main() {
  late _FakeDocuments documents;
  late FirestoreRemoteProgress store;

  setUp(() {
    documents = _FakeDocuments();
    store = FirestoreRemoteProgress(documents);
  });

  group('progressOf', () {
    test('reads a stored lesson', () {
      expect(progressOf(_stored('l1', 80)), _progress('l1', 80));
    });

    test('skips documents it does not understand', () {
      final time = Timestamp.fromDate(_completed);
      expect(progressOf((id: 'l1', data: {'bestScore': 80})), isNull);
      for (final score in [-1, 101]) {
        expect(
          progressOf((
            id: 'l1',
            data: {'bestScore': score, 'completedAt': time, 'updatedAt': time},
          )),
          isNull,
        );
      }
    });
  });

  test('writes the server time, not the device time', () {
    final document = documentOf(_progress('l1', 60));

    expect(document.id, 'l1');
    expect(document.data, {
      'bestScore': 60,
      'completedAt': Timestamp.fromDate(_completed),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  test('fetches every lesson of a learner and skips broken ones', () async {
    documents.users['alice'] = [
      _stored('l1', 70),
      (id: 'broken', data: {'bestScore': 'high'}),
    ];

    expect((await store.fetchAll('alice')).valueOrNull, [_progress('l1', 70)]);
  });

  test('reports a fetch that fails', () async {
    documents.error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );

    expect(
      await store.fetchAll('alice'),
      const Err<List<LessonProgress>>(NetworkFailure()),
    );
  });

  test('saves lessons in batches', () async {
    final items = [
      for (var index = 0; index <= FirestoreRemoteProgress.batchLimit; index++)
        _progress('l$index', 60),
    ];

    expect(await store.saveAll('alice', items), const Ok<void>(null));
    expect(documents.writes, [FirestoreRemoteProgress.batchLimit, 1]);
    expect(await store.saveAll('bob', const []), const Ok<void>(null));
    expect(documents.writes, hasLength(2));
  });

  test('reports a save that is refused', () async {
    documents.error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );

    expect(
      await store.saveAll('alice', [_progress('l1', 60)]),
      const Err<void>(PermissionDeniedFailure()),
    );
  });

  test('deletes every lesson of a learner in batches', () async {
    documents.users['alice'] = [
      for (var index = 0; index <= FirestoreRemoteProgress.batchLimit; index++)
        _stored('l$index', 50),
    ];

    expect(await store.deleteAll('alice'), const Ok<void>(null));
    expect(documents.deletes, [FirestoreRemoteProgress.batchLimit, 1]);
    expect(documents.users['alice'], isEmpty);
  });

  test('reports a delete that fails', () async {
    documents.error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'internal',
    );

    expect(
      (await store.deleteAll('alice')).failureOrNull,
      isA<UnexpectedFailure>(),
    );
  });
}
