import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura_core/gestura_core.dart';

abstract interface class SavedSignsRepository {
  Stream<Result<List<SignId>>> watchSaved();

  Future<Result<bool>> isSaved(SignId sign);

  Future<Result<void>> setSaved(SignId sign, {required bool saved});

  Future<Result<void>> clear();
}
