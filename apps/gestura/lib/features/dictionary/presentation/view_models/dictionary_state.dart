import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/dictionary/domain/sign_sections.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class DictionaryState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class DictionaryLoading extends DictionaryState {
  const new();
}

final class DictionaryLoaded extends DictionaryState {
  const new({
    required this.categories,
    required this.results,
    this.query = '',
    this.category,
  });

  final List<SignCategory> categories;
  final List<Sign> results;
  final String query;
  final CategoryId? category;

  bool get isSearching => query.trim().isNotEmpty;

  bool get hasPlaceholders => results.any((sign) => sign.isPlaceholder);

  List<SignSection> get sections => isSearching
      ? [SignSection(initial: '', signs: results)]
      : sectionsByInitial(results);

  @override
  List<Object?> get props => [categories, results, query, category];
}

final class DictionaryFailed extends DictionaryState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
