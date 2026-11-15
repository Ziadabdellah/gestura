import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/account_view_model.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/data/progress_documents.dart';
import 'package:gestura/features/progress/data/progress_sync.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/progress/domain/remote_progress_store.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:integration_test/integration_test.dart';

import 'support/emulated_auth.dart';

const AppConfig _dev = AppConfig(flavor: Flavor.dev);
const LessonId _first = LessonId('demo-a1-1');
const LessonId _second = LessonId('demo-a1-2');

DocumentReference<Map<String, dynamic>> _cloud(String uid, LessonId lesson) =>
    FirebaseFirestore.instance.doc('users/$uid/progress/${lesson.value}');

Future<void> _clearLocal() async {
  final database = getIt<AppDatabase>();
  await database.delete(database.progress).go();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await emulatedAuth();
    await configureDependencies(_dev);
  });

  tearDown(() async {
    getIt<ProgressSync>().stop();
    await _clearLocal();
    await getIt.reset();
    await signOutEverywhere();
  });

  testWidgets('a finished lesson reaches the cloud and comes back on a new '
      'device', (tester) async {
    final guest = await signInAsGuest();
    final sync = getIt<ProgressSync>()..start();
    await getIt<ProgressRepository>().recordCompletion(_first, score: 80);
    await tester.pump(const Duration(seconds: 2));

    final stored = await _cloud(guest.uid, _first).get();
    expect(stored.data()?['bestScore'], 80);
    expect(stored.data()?['updatedAt'], isA<Timestamp>());

    await _cloud(guest.uid, _second).set({
      'bestScore': 60,
      'completedAt': Timestamp.now(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _clearLocal();
    expect(await sync.sync(guest.uid), const Ok<void>(null));

    final local =
        (await getIt<ProgressRepository>().watchAll().first).valueOrNull!;
    expect(local[_first]?.bestScore, 80);
    expect(local[_second]?.bestScore, 60);
  });

  testWidgets("the cloud refuses to write another learner's progress", (
    tester,
  ) async {
    await signInAsGuest();
    final documents = getIt<ProgressDocuments>();

    await expectLater(
      documents.write('somebody-else', [
        (
          id: 'demo-a1-1',
          data: {
            'bestScore': 100,
            'completedAt': Timestamp.now(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        ),
      ]),
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );
  });

  testWidgets('deleting the account removes the progress in the cloud', (
    tester,
  ) async {
    final email = uniqueEmail();
    final auth = await emulatedAuth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: 'signing-is-fun',
    );
    final uid = credential.user!.uid;
    await getIt<ProgressRepository>().recordCompletion(_first, score: 90);
    expect(await getIt<ProgressSync>().sync(uid), const Ok<void>(null));
    expect((await _cloud(uid, _first).get()).exists, isTrue);

    final account = AccountViewModel(
      getIt<AuthRepository>(),
      getIt<ProgressRepository>(),
      getIt<RemoteProgressStore>(),
    );
    final result = await account.deleteAccount(password: 'signing-is-fun');
    await account.close();

    expect(result, const Ok<void>(null));
    expect(auth.currentUser, isNull);
    expect(
      (await getIt<ProgressRepository>().watchAll().first).valueOrNull,
      isEmpty,
    );
    await signInAsGuest();
    await expectLater(
      _cloud(uid, _first).get(),
      throwsA(isA<FirebaseException>()),
    );
  });
}
