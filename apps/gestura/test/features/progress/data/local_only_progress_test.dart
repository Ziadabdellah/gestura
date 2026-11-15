import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/progress/data/local_only_progress.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/fake_progress_repository.dart';

void main() {
  test('keeps progress on the device in test builds', () async {
    const store = LocalOnlyProgress();

    expect((await store.fetchAll('uid')).valueOrNull, isEmpty);
    expect(
      await store.saveAll('uid', [completed('demo-a1-1')]),
      const Ok<void>(null),
    );
    expect(await store.deleteAll('uid'), const Ok<void>(null));
  });
}
