import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_core/gestura_core.dart';

extension FailurePresentation on Failure {
  String message(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.failureNetwork,
    NotFoundFailure() => l10n.failureNotFound,
    PermissionDeniedFailure() => l10n.failurePermissionDenied,
    StorageFullFailure() => l10n.failureStorageFull,
    UnexpectedFailure() => l10n.failureUnexpected,
  };

  IconData get icon => switch (this) {
    NetworkFailure() => Icons.cloud_off_rounded,
    NotFoundFailure() => Icons.search_off_rounded,
    PermissionDeniedFailure() => Icons.lock_outline_rounded,
    StorageFullFailure() => Icons.sd_card_alert_outlined,
    UnexpectedFailure() => Icons.error_outline_rounded,
  };
}
