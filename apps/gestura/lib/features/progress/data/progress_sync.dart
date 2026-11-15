import 'dart:async';

import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/progress/domain/remote_progress_store.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
final class ProgressSync {
  new(this._auth, this._local, this._remote);

  final AuthRepository _auth;
  final ProgressRepository _local;
  final RemoteProgressStore _remote;
  StreamSubscription<AppUser?>? _users;
  StreamSubscription<Result<ProgressByLesson>>? _changes;
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
    final remote = await _remote.fetchAll(userId);
    final merged = switch (remote) {
      Ok(:final value) => await _local.merge(value),
      Err(:final failure) => Err<void>(failure),
    };
    if (merged case Err()) return merged;
    final local = await _local.readAll();
    return switch (local) {
      Ok(:final value) => await _remote.saveAll(userId, value.values),
      Err(:final failure) => Err(failure),
    };
  }

  Future<void> _follow(AppUser? user) async {
    final userId = user?.id;
    if (userId == _userId) return;
    _userId = userId;
    _stopFollowingChanges();
    if (userId == null) return;
    await sync(userId);
    if (_userId != userId) return;
    _changes = _local.watchAll().skip(1).listen((result) {
      if (result case Ok(:final value)) {
        unawaited(_remote.saveAll(userId, value.values));
      }
    });
  }

  void _stopFollowingChanges() {
    unawaited(_changes?.cancel());
    _changes = null;
  }

  void stop() {
    unawaited(_users?.cancel());
    _users = null;
    _stopFollowingChanges();
    _userId = null;
  }
}
