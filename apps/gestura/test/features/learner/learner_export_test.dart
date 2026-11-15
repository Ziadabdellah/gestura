import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/learner/learner_export.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_activity_repository.dart';
import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_review_repository.dart';
import '../../helpers/fake_saved_signs_repository.dart';
import '../../helpers/fake_settings_repository.dart';

void main() {
  late Directory folder;
  late FakeReviewRepository reviews;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('gestura_export');
    reviews = FakeReviewRepository();
    await reviews.addSigns({const SignId('hello')});
  });

  tearDown(() => folder.delete(recursive: true));

  LearnerExport build({
    FakeActivityRepository? activity,
    FakeSavedSignsRepository? saved,
  }) => LearnerExport(
    FakeProgressRepository([completed('demo-a1-1')]),
    reviews,
    activity ??
        FakeActivityRepository([
          DailyActivity(day: DateTime(2026, 11, 14), lessons: 1, seconds: 120),
        ]),
    saved ?? FakeSavedSignsRepository([const SignId('yes')]),
    FakeSettingsRepository(
      const AppSettings(language: AppLanguage.arabic, reminderMinutes: 480),
    ),
    directory: () async => folder,
  );

  test('writes everything the learner owns into one JSON file', () async {
    final result = await withClock(
      Clock.fixed(DateTime(2026, 11, 15, 9)),
      () => build().toFile(),
    );

    final file = result.valueOrNull!;
    expect(file.path, endsWith('gestura-data-2026-11-15.json'));
    final data = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    expect(data['app'], 'Gestura');
    expect(data['format'], LearnerExport.format);
    expect((data['progress']! as List).single, containsPair('bestScore', 90));
    expect(
      (data['reviewCards']! as List).single,
      containsPair('signId', 'hello'),
    );
    expect(
      (data['activity']! as List).single,
      containsPair('day', '2026-11-14'),
    );
    expect(data['savedSigns'], ['yes']);
    expect(data['settings'], containsPair('language', 'ar'));
    expect(data['settings'], containsPair('reminderMinutes', 480));
  });

  test('reports data that cannot be read', () async {
    reviews.failure = const StorageFullFailure();

    expect(await build().toFile(), const Err<File>(StorageFullFailure()));
  });

  test('reports activity or saved signs that cannot be read', () async {
    final activity = FakeActivityRepository()
      ..failure = const StorageFullFailure();
    final saved = FakeSavedSignsRepository()
      ..failure = const StorageFullFailure();

    expect((await build(activity: activity).toJson()).failureOrNull, isNotNull);
    expect((await build(saved: saved).toJson()).failureOrNull, isNotNull);
  });

  test('reports a file that cannot be written', () async {
    await folder.delete(recursive: true);
    final result = await build().toFile();
    await folder.create();

    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });
}
