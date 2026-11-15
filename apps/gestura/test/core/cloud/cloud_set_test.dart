import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/cloud/cloud_set.dart';
import 'package:gestura/core/cloud/user_documents.dart';
import 'package:gestura_core/gestura_core.dart';

class _Codec implements DocumentCodec<int> {
  const new();

  @override
  String idOf(int item) => 'n$item';

  @override
  StoredDocument encode(int item) => (id: idOf(item), data: {'value': item});

  @override
  int? decode(StoredDocument document) => switch (document.data) {
    {'value': final int value} => value,
    _ => null,
  };
}

class _FakeDocuments implements UserDocuments {
  final Map<String, List<StoredDocument>> collections = {};
  final List<String> calls = [];
  FirebaseException? error;

  @override
  Future<List<StoredDocument>> read(String userId, String collection) async {
    if (error case final FirebaseException error) throw error;
    return collections['$userId/$collection'] ?? const [];
  }

  @override
  Future<void> write(
    String userId,
    String collection,
    List<StoredDocument> documents,
  ) async {
    if (error case final FirebaseException error) throw error;
    calls.add('write:$collection:${documents.length}');
    collections.putIfAbsent('$userId/$collection', () => []).addAll(documents);
  }

  @override
  Future<void> delete(
    String userId,
    String collection,
    List<String> ids,
  ) async {
    calls.add('delete:$collection:${ids.length}');
    collections['$userId/$collection']?.removeWhere(
      (document) => ids.contains(document.id),
    );
  }
}

void main() {
  late _FakeDocuments documents;
  late FirestoreCloudSet<int> numbers;

  setUp(() {
    documents = _FakeDocuments();
    numbers = FirestoreCloudSet(documents, 'numbers', const _Codec());
  });

  test('writes in batches and reads back what it understands', () async {
    final all = List.generate(FirestoreCloudSet.batchLimit + 5, (i) => i);
    documents.collections['u/numbers'] = [
      (id: 'junk', data: {'value': 'x'}),
    ];

    expect(await numbers.saveAll('u', all), const Ok<void>(null));
    expect(documents.calls, ['write:numbers:400', 'write:numbers:5']);
    expect((await numbers.fetchAll('u')).valueOrNull, all);
    expect(numbers.collection, 'numbers');
  });

  test('deletes everything in batches', () async {
    await numbers.saveAll(
      'u',
      List.generate(FirestoreCloudSet.batchLimit + 1, (i) => i),
    );
    documents.calls.clear();

    expect(await numbers.deleteAll('u'), const Ok<void>(null));
    expect(documents.calls, ['delete:numbers:400', 'delete:numbers:1']);
    expect((await numbers.fetchAll('u')).valueOrNull, isEmpty);
  });

  test('turns cloud errors into failures', () async {
    documents.error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );

    expect(await numbers.fetchAll('u'), const Err<List<int>>(NetworkFailure()));
    expect(await numbers.saveAll('u', [1]), const Err<void>(NetworkFailure()));
    expect(await numbers.deleteAll('u'), const Err<void>(NetworkFailure()));
  });

  test('a device-only set keeps nothing in the cloud', () async {
    const device = DeviceOnlySet<int>();

    expect((await device.fetchAll('u')).valueOrNull, isEmpty);
    expect(await device.saveAll('u', [1]), const Ok<void>(null));
    expect(await device.deleteAll('u'), const Ok<void>(null));
  });
}
