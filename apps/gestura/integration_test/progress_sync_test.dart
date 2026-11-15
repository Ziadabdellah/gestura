import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/core/cloud/user_documents.dart';
import 'package:gestura/core/database/app_database.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/account_view_model.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/learner/data/learner_cloud_module.dart';
import 'package:gestura/features/learner/learner_cloud.dart';
import 'package:gestura/features/learner/learner_data.dart';
import 'package:gestura/features/learner/learner_sync.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
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
  await database.delete(database.reviewCards).go();
  await database.delete(database.dailyActivity).go();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await emulatedAuth();
    await configureDependencies(_dev);
    getIt
      ..unregister<LearnerCloud>()
      ..registerSingleton<LearnerCloud>(
        firestoreLearnerCloud(getIt<UserDocuments>()),
      )
      ..unregister<LearnerSync>()
      ..registerSingleton(
        LearnerSync(getIt(), getIt(), getIt(), getIt(), getIt()),
      );
  });

  tearDown(() async {
    getIt<LearnerSync>().stop();
    await _clearLocal();
    await getIt.reset();
    await signOutEverywhere();
  });

  testWidgets('a finished lesson reaches the cloud and comes back on a new '
      'device', (tester) async {
    final guest = await signInAsGuest();
    final sync = getIt<LearnerSync>()..start();
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

  testWidgets('review cards and daily activity follow the learner', (
    tester,
  ) async {
    final guest = await signInAsGuest();
    final sync = getIt<LearnerSync>()..start();
    await getIt<ReviewRepository>().addSigns({const SignId('hello')});
    await getIt<ActivityRepository>().recordLesson(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 2));

    final users = FirebaseFirestore.instance.doc('users/${guest.uid}');
    final card = await users.collection('cards').doc('hello').get();
    expect(card.data()?['repetitions'], 0);
    final days = await users.collection('activity').get();
    expect(days.docs.single.data()['lessons'], 1);

    await _clearLocal();
    expect(await sync.sync(guest.uid), const Ok<void>(null));

    final cards = (await getIt<ReviewRepository>().readAll()).valueOrNull!;
    expect(cards.single.signId, const SignId('hello'));
    final activity = (await getIt<ActivityRepository>().readAll()).valueOrNull!;
    expect(activity.single.seconds, 120);
  });

  testWidgets("the cloud refuses to write another learner's progress", (
    tester,
  ) async {
    await signInAsGuest();
    final documents = getIt<UserDocuments>();

    await expectLater(
      documents.write('somebody-else', 'progress', [
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
    await getIt<ReviewRepository>().addSigns({const SignId('hello')});
    expect(await getIt<LearnerSync>().sync(uid), const Ok<void>(null));
    expect((await _cloud(uid, _first).get()).exists, isTrue);
    final card = FirebaseFirestore.instance.doc('users/$uid/cards/hello');
    expect((await card.get()).exists, isTrue);

    final account = AccountViewModel(
      getIt<AuthRepository>(),
      getIt<LearnerData>(),
      getIt<LearnerCloud>(),
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
    await expectLater(card.get(), throwsA(isA<FirebaseException>()));
  });
}
