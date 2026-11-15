import 'dart:async';

import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/saved/domain/saved_signs_repository.dart';
import 'package:gestura_core/gestura_core.dart';

class FakeSavedSignsRepository implements SavedSignsRepository {
  new([Iterable<SignId> initial = const []]) : saved = [...initial];

  final List<SignId> saved;
  Failure? failure;
  final StreamController<void> _changes = StreamController.broadcast();

  Result<List<SignId>> _snapshot() => switch (failure) {
    final Failure failure => Err(failure),
    null => Ok(List.of(saved)),
  };

  @override
  Stream<Result<List<SignId>>> watchSaved() => Stream.multi((controller) {
    controller.add(_snapshot());
    final subscription = _changes.stream.listen(
      (_) => controller.add(_snapshot()),
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<Result<bool>> isSaved(SignId sign) async => switch (failure) {
    final Failure failure => Err(failure),
    null => Ok(saved.contains(sign)),
  };

  @override
  Future<Result<void>> setSaved(SignId sign, {required bool saved}) async {
    if (failure case final Failure failure) return Err(failure);
    this.saved.remove(sign);
    if (saved) this.saved.insert(0, sign);
    _changes.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> clear() async {
    saved.clear();
    _changes.add(null);
    return const Ok(null);
  }
}
