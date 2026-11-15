import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura/features/saved/domain/saved_signs_repository.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

@lazySingleton
final class LearnerExport {
  const new(
    this._progress,
    this._reviews,
    this._activity,
    this._saved,
    this._settings, {
    @ignoreParam this.directory = getTemporaryDirectory,
  });

  final Future<Directory> Function() directory;

  static const int format = 1;

  final ProgressRepository _progress;
  final ReviewRepository _reviews;
  final ActivityRepository _activity;
  final SavedSignsRepository _saved;
  final SettingsRepository _settings;

  static String _time(DateTime value) => value.toUtc().toIso8601String();

  Future<Result<File>> toFile() async {
    final json = await toJson();
    if (json case Err(:final failure)) return Err(failure);
    return await Result.guard(() async {
      final day = dayKey(clock.now());
      final file = File('${(await directory()).path}/gestura-data-$day.json');
      await file.writeAsString(json.valueOrNull!);
      return file;
    }, onError: (error, stackTrace) => UnexpectedFailure(error));
  }

  Future<Result<String>> toJson() async {
    final (progress, cards, days, saved) = await (
      _progress.readAll(),
      _reviews.readAll(),
      _activity.readAll(),
      _saved.watchSaved().first,
    ).wait;
    switch ((progress, cards, days, saved)) {
      case (
        Ok(value: final progress),
        Ok(value: final cards),
        Ok(value: final days),
        Ok(value: final saved),
      ):
        final settings = _settings.load();
        return Ok(
          const JsonEncoder.withIndent('  ').convert({
            'app': 'Gestura',
            'format': format,
            'exportedAt': _time(clock.now()),
            'progress': [
              for (final item in progress.values)
                {
                  'lessonId': item.lessonId.value,
                  'bestScore': item.bestScore,
                  'completedAt': _time(item.completedAt),
                  'updatedAt': _time(item.updatedAt),
                },
            ],
            'reviewCards': [
              for (final card in cards)
                {
                  'signId': card.signId.value,
                  'repetitions': card.state.repetitions,
                  'intervalDays': card.state.intervalDays,
                  'ease': card.state.ease,
                  'dueAt': _time(card.state.dueAt),
                  'lapses': card.state.lapses,
                  'updatedAt': _time(card.updatedAt),
                },
            ],
            'activity': [
              for (final day in days)
                {
                  'day': dayKey(day.day),
                  'lessons': day.lessons,
                  'reviews': day.reviews,
                  'seconds': day.seconds,
                },
            ],
            'savedSigns': [for (final sign in saved) sign.value],
            'settings': {
              'language': settings.language.code,
              'theme': settings.theme.name,
              'reduceMotion': settings.reduceMotion,
              'signLanguage': settings.signLanguage,
              'dailyGoalMinutes': settings.dailyGoal.minutes,
              'dominantHand': settings.dominantHand.name,
              'reminderMinutes': settings.reminderMinutes,
              'analyticsConsent': settings.analyticsConsent,
              'crashReportsConsent': settings.crashReportsConsent,
            },
          }),
        );
      case (Err(:final failure), _, _, _) ||
          (_, Err(:final failure), _, _) ||
          (_, _, Err(:final failure), _) ||
          (_, _, _, Err(:final failure)):
        return Err(failure);
    }
  }
}
