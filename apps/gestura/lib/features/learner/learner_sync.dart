import 'dart:async';

import 'package:gestura/core/cloud/cloud_set.dart';
import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/learner/learner_cloud.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

final class SyncChannel<T> {
  new({
    required this.remote,
    required this.idOf,
    required this.read,
    required this.watch,
    required this.merge,
  });

  final CloudSet<T> remote;
  final String Function(T item) idOf;
  final Future<Result<Iterable<T>>> Function() read;
  final Stream<Result<Iterable<T>>> Function() watch;
  final Future<Result<void>> Function(Iterable<T> items) merge;
  Map<String, T> _pushed = {};

  Future<Result<void>> sync(String userId) async {
    final fetched = await remote.fetchAll(userId);
    final merged = switch (fetched) {
      Ok(:final value) => await merge(value),
      Err(:final failure) => Err<void>(failure),
    };
    if (merged case Err()) return merged;
    final local = await read();
    if (local case Err(:final failure)) return Err(failure);
    final items = local.valueOrNull!.toList();
    final saved = await remote.saveAll(userId, items);
    if (saved case Ok()) _pushed = {for (final item in items) idOf(item): item};
    return saved;
  }

  StreamSubscription<Result<Iterable<T>>> follow(String userId) =>
      watch().skip(1).listen((result) {
        if (result case Ok(:final value)) {
          final changed = [
            for (final item in value)
              if (_pushed[idOf(item)] != item) item,
          ];
          if (changed.isEmpty) return;
          for (final item in changed) {
            _pushed[idOf(item)] = item;
          }
          unawaited(remote.saveAll(userId, changed));
        }
      });

  void forget() => _pushed = {};
}

@lazySingleton
final class LearnerSync {
  new(
    this._auth,
    ProgressRepository progress,
    ReviewRepository reviews,
    ActivityRepository activity,
    LearnerCloud cloud,
  ) : _channels = [
        SyncChannel<LessonProgress>(
          remote: cloud.progress,
          idOf: (item) => item.lessonId.value,
          read: () async => (await progress.readAll()).map((all) => all.values),
          watch: () => progress.watchAll().map(
            (result) => result.map((all) => all.values),
          ),
          merge: progress.merge,
        ),
        SyncChannel<ReviewCard>(
          remote: cloud.cards,
          idOf: (item) => item.signId.value,
          read: reviews.readAll,
          watch: reviews.watchAll,
          merge: reviews.merge,
        ),
        SyncChannel<DailyActivity>(
          remote: cloud.activity,
          idOf: (item) => dayKey(item.day),
          read: activity.readAll,
          watch: activity.watchAll,
          merge: activity.merge,
        ),
      ];

  final AuthRepository _auth;
  final List<SyncChannel<Object?>> _channels;
  StreamSubscription<AppUser?>? _users;
  List<StreamSubscription<Object?>> _changes = [];
  String? _userId;

  void start() {
    _users ??= _auth.watchUser().listen((user) => unawaited(_follow(user)));
    unawaited(_follow(_auth.currentUser));
  }

  Future<Result<void>> refresh() async {
    final userId = _userId;
    if (userId == null) return const Ok(null);
    return await sync(userId);
  }

  Future<Result<void>> sync(String userId) async {
    Result<void> outcome = const Ok(null);
    for (final channel in _channels) {
      final result = await channel.sync(userId);
      if (result case Err() when outcome is Ok) outcome = result;
    }
    return outcome;
  }

  Future<void> _follow(AppUser? user) async {
    final userId = user?.id;
    if (userId == _userId) return;
    _userId = userId;
    _stopFollowingChanges();
    if (userId == null) return;
    await sync(userId);
    if (_userId != userId) return;
    _changes = [for (final channel in _channels) channel.follow(userId)];
  }

  void _stopFollowingChanges() {
    for (final subscription in _changes) {
      unawaited(subscription.cancel());
    }
    _changes = [];
    for (final channel in _channels) {
      channel.forget();
    }
  }

  void stop() {
    unawaited(_users?.cancel());
    _users = null;
    _stopFollowingChanges();
    _userId = null;
  }
}
