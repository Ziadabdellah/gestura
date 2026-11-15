import 'package:equatable/equatable.dart';

sealed class OfflinePackState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class OfflinePackChecking extends OfflinePackState {
  const new();
}

final class OfflinePackUnavailable extends OfflinePackState {
  const new();
}

final class OfflinePackIdle extends OfflinePackState {
  const new({required this.files, required this.saved});

  final int files;
  final int saved;

  bool get complete => saved == files;

  @override
  List<Object?> get props => [files, saved];
}

final class OfflinePackDownloading extends OfflinePackState {
  const new({required this.done, required this.total});

  final int done;
  final int total;

  double get fraction => total == 0 ? 1 : done / total;

  @override
  List<Object?> get props => [done, total];
}

final class OfflinePackFailed extends OfflinePackState {
  const new({required this.saved, required this.files});

  final int saved;
  final int files;

  @override
  List<Object?> get props => [saved, files];
}
