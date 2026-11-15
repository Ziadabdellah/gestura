import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/data/progress_sync.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/fake_remote_progress_store.dart';

class _BrokenLocal extends FakeProgressRepository {
  @override
  Future<Result<ProgressByLesson>> readAll() async =>
      const Err(StorageFullFailure());
}

void main() {
  late FakeAuthRepository auth;
  late FakeProgressRepository local;
  late FakeRemoteProgressStore remote;
  late ProgressSync sync;

  setUp(() {
    auth = FakeAuthRepository();
    local = FakeProgressRepository([completed('demo-a1-1', score: 60)]);
    remote = FakeRemoteProgressStore()
      ..users['guest-uid'] = {
        const LessonId('demo-a1-2'): completed('demo-a1-2', score: 80),
        const LessonId('demo-a1-1'): completed('demo-a1-1', score: 95),
      };
    sync = ProgressSync(auth, local, remote);
  });

  tearDown(() => sync.stop());

  Future<void> settle() => pumpEventQueue();

  test('pulls the cloud progress, keeps the best and pushes it back', () async {
    sync.start();
    await settle();

    expect(local.stored[const LessonId('demo-a1-1')]?.bestScore, 95);
    expect(local.stored[const LessonId('demo-a1-2')]?.bestScore, 80);
    expect(remote.calls, ['fetch:guest-uid', 'save:guest-uid:2']);
  });

  test('pushes every new result while signed in', () async {
    sync.start();
    await settle();
    remote.calls.clear();

    await local.recordCompletion(const LessonId('demo-a1-3'), score: 70);
    await settle();

    expect(remote.calls, ['save:guest-uid:3']);
    expect(remote.users['guest-uid'], hasLength(3));
  });

  test('follows the signed-in user and stops when signed out', () async {
    sync.start();
    await settle();

    auth.user = const MemberUser(
      'member-uid',
      email: 'a@b.co',
      emailVerified: true,
    );
    await settle();

    expect(remote.calls.last, 'save:member-uid:2');

    auth.user = null;
    await settle();
    remote.calls.clear();
    await local.recordCompletion(const LessonId('demo-a1-3'), score: 70);
    await settle();

    expect(remote.calls, isEmpty);
  });

  test('does nothing without a user and refreshes the current one', () async {
    auth.user = null;
    sync.start();
    await settle();

    expect(remote.calls, isEmpty);
    expect(await sync.refresh(), const Ok<void>(null));

    auth.user = testGuest;
    await settle();
    remote.calls.clear();

    expect(await sync.refresh(), const Ok<void>(null));
    expect(remote.calls, ['fetch:guest-uid', 'save:guest-uid:2']);
  });

  test('ignores the same user twice and starts only once', () async {
    sync
      ..start()
      ..start();
    await settle();
    auth.user = testGuest;
    await settle();

    expect(remote.calls, ['fetch:guest-uid', 'save:guest-uid:2']);
  });

  test('reports a cloud that cannot be reached and keeps local data', () async {
    remote.fetchFailure = const NetworkFailure();

    expect(await sync.sync('guest-uid'), const Err<void>(NetworkFailure()));
    expect(local.stored, hasLength(1));
    expect(remote.calls, ['fetch:guest-uid']);
  });

  test('reports a merge that fails', () async {
    local.saveFailure = const StorageFullFailure();

    expect(await sync.sync('guest-uid'), const Err<void>(StorageFullFailure()));
  });

  test('reports local progress that cannot be read', () async {
    final broken = ProgressSync(auth, _BrokenLocal(), remote);

    expect(
      await broken.sync('guest-uid'),
      const Err<void>(StorageFullFailure()),
    );
  });

  test('drops a sync for a user who left while it ran', () async {
    final hold = Completer<void>();
    final slow = _SlowRemote(hold);
    final slowSync = ProgressSync(auth, local, slow)..start();
    await settle();

    auth.user = null;
    await settle();
    hold.complete();
    await settle();

    await local.recordCompletion(const LessonId('demo-a1-3'), score: 70);
    await settle();
    expect(slow.saves, 1);
    slowSync.stop();
  });
}

class _SlowRemote extends FakeRemoteProgressStore {
  new(this._hold);

  final Completer<void> _hold;
  int saves = 0;

  @override
  Future<Result<List<LessonProgress>>> fetchAll(String userId) async {
    await _hold.future;
    return await super.fetchAll(userId);
  }

  @override
  Future<Result<void>> saveAll(
    String userId,
    Iterable<LessonProgress> progress,
  ) {
    saves++;
    return super.saveAll(userId, progress);
  }
}
