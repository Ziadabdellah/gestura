import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:meta/meta.dart';

@immutable
final class ReviewCard {
  const new({
    required this.signId,
    required this.state,
    required this.updatedAt,
  });

  final SignId signId;
  final CardState state;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewCard &&
          other.signId == signId &&
          other.state == state &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(signId, state, updatedAt);
}
