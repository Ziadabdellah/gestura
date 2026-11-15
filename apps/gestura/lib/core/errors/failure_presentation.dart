import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_core/gestura_core.dart';

extension FailurePresentation on Failure {
  String message(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.failureNetwork,
    NotFoundFailure() => l10n.failureNotFound,
    PermissionDeniedFailure() => l10n.failurePermissionDenied,
    StorageFullFailure() => l10n.failureStorageFull,
    NoContentFailure() => l10n.failureNoContent,
    AuthFailure(:final problem) => switch (problem) {
      AuthProblem.invalidEmail => l10n.authInvalidEmail,
      AuthProblem.wrongCredentials => l10n.authWrongCredentials,
      AuthProblem.emailInUse => l10n.authEmailInUse,
      AuthProblem.weakPassword => l10n.authWeakPassword,
      AuthProblem.tooManyRequests => l10n.authTooManyRequests,
      AuthProblem.accountDisabled => l10n.authAccountDisabled,
      AuthProblem.unavailable => l10n.authUnavailable,
      AuthProblem.signInAgain => l10n.authSignInAgain,
      AuthProblem.cancelled => l10n.authCancelled,
    },
    UnexpectedFailure() => l10n.failureUnexpected,
  };

  IconData get icon => switch (this) {
    NetworkFailure() => Icons.cloud_off_rounded,
    NotFoundFailure() => Icons.search_off_rounded,
    PermissionDeniedFailure() => Icons.lock_outline_rounded,
    StorageFullFailure() => Icons.sd_card_alert_outlined,
    NoContentFailure() => Icons.hourglass_top_rounded,
    AuthFailure() => Icons.no_accounts_outlined,
    UnexpectedFailure() => Icons.error_outline_rounded,
  };
}
