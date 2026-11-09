import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/learn/presentation/view_models/learn_state.dart';
import 'package:gestura_core/gestura_core.dart';

class LearnViewModel extends Cubit<LearnState> {
  new(this._content) : super(const LearnLoading());

  final ContentRepository _content;

  Future<void> load() async {
    if (state is! LearnLoading) emit(const LearnLoading());
    final (packResult, coursesResult) = await (
      _content.pack(),
      _content.courses(),
    ).wait;
    if (isClosed) return;
    emit(switch ((packResult, coursesResult)) {
      (Ok(value: final pack), Ok(value: [final course, ...])) => LearnLoaded(
        pack: pack,
        course: course,
      ),
      (Ok(), Ok()) => const LearnFailed(NotFoundFailure()),
      (Err(:final failure), _) ||
      (_, Err(:final failure)) => LearnFailed(failure),
    });
  }
}
