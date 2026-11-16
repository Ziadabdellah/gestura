import 'package:equatable/equatable.dart';

final class ContentDoc extends Equatable {
  const new(this.id, this.data);

  final String id;
  final Map<String, Object?> data;

  bool get published => data['published'] == true;

  @override
  List<Object?> get props => [id, data];
}
