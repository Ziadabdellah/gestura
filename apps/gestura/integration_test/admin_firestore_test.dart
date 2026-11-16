import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/admin/data/content_store.dart';
import 'package:gestura/features/admin/data/firestore_admin_access.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/content/data/published_catalog.dart';
import 'package:integration_test/integration_test.dart';

import 'support/emulated_auth.dart';

Future<void> _asOwner(String method, Uri uri, Object body) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri)
      ..headers.set('Authorization', 'Bearer owner')
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    final response = await request.close();
    await response.drain<void>();
    expect(response.statusCode, lessThan(300));
  } finally {
    client.close();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an admin reads and edits content in Firestore', (_) async {
    final auth = await emulatedAuth();
    final firestore = FirebaseFirestore.instance;
    final projectId = Firebase.app().options.projectId;
    final access = FirestoreAdminAccess(firestore);
    final store = FirestoreContentStore(firestore);
    final email = uniqueEmail();

    final created = await auth.createUserWithEmailAndPassword(
      email: email,
      password: 'secret123',
    );
    final uid = created.user!.uid;
    expect(await access.isAdmin(null), isFalse);
    expect(
      await access.isAdmin(MemberUser(uid, email: email, emailVerified: false)),
      isFalse,
    );
    expect(
      await access.isAdmin(MemberUser(uid, email: email, emailVerified: true)),
      isFalse,
    );

    await _asOwner(
      'POST',
      Uri.http(
        '$authEmulatorHost:$authEmulatorPort',
        '/identitytoolkit.googleapis.com/v1/projects/$projectId/accounts:update',
      ),
      {'localId': uid, 'emailVerified': true},
    );
    await _asOwner(
      'PATCH',
      Uri.http(
        '$authEmulatorHost:$firestoreEmulatorPort',
        '/v1/projects/$projectId/databases/(default)/documents/admins/$email',
      ),
      {'fields': <String, Object?>{}},
    );
    await auth.currentUser!.getIdToken(true);
    final admin = MemberUser(uid, email: email, emailVerified: true);
    expect(await access.isAdmin(admin), isTrue);

    final id = 'it-${DateTime.now().microsecondsSinceEpoch}';
    expect(await store.exists(ContentKind.categories, id), isFalse);
    expect(await store.read(ContentKind.categories, id), isNull);
    await store.save(ContentKind.categories, id, {
      'signLanguage': 'ase',
      'name': {'en': 'Test'},
      'order': 0,
      'published': false,
    });
    expect((await store.read(ContentKind.categories, id))?.id, id);
    final docs = await store.watch(ContentKind.categories).first;
    expect(docs.map((doc) => doc.id), contains(id));
    final pack = 'p${DateTime.now().millisecondsSinceEpoch % 100000000}';
    await store.save(ContentKind.signLanguages, pack, {
      'name': {'en': 'Test pack'},
      'fingerspelling': 'oneHanded',
      'placeholder': true,
      'order': 0,
      'published': true,
    });
    final catalog = await FirestorePublishedCatalog(firestore).load(pack);
    expect((catalog!['pack']! as Map)['code'], pack);
    await store.delete(ContentKind.signLanguages, pack);
    await store.delete(ContentKind.categories, id);
    expect(await store.exists(ContentKind.categories, id), isFalse);

    await signOutEverywhere();
    expect(await access.isAdmin(admin), isFalse);
  });
}
