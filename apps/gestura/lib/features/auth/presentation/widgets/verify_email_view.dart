import 'package:flutter/material.dart';
import 'package:gestura/features/auth/presentation/view_models/verify_email_state.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_message.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class VerifyEmailView extends StatelessWidget {
  const new({
    required this.state,
    required this.onCheck,
    required this.onResend,
    required this.onDone,
    super.key,
  });

  final VerifyEmailState state;
  final VoidCallback onCheck;
  final VoidCallback onResend;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    return switch (state) {
      VerifyEmailConfirmed() => AuthFormLayout(
        title: l10n.emailConfirmedTitle,
        children: [
          AuthMessage(
            text: l10n.emailConfirmedMessage,
            tone: AuthMessageTone.success,
          ),
          SizedBox(height: sizes.lg),
          GButton(label: l10n.continueAction, expand: true, onPressed: onDone),
        ],
      ),
      VerifyEmailPending(
        :final email,
        :final busy,
        :final notice,
        :final failure,
      ) =>
        AuthFormLayout(
          title: l10n.verifyEmailTitle,
          subtitle: l10n.verifyEmailMessage(email),
          children: [
            ...switch ((failure, notice)) {
              (final failure?, _) => [
                AuthMessage.failure(failure, l10n: l10n),
                SizedBox(height: sizes.md),
              ],
              (null, VerifyEmailNotice.sent) => [
                AuthMessage(
                  text: l10n.verificationSent,
                  tone: AuthMessageTone.success,
                ),
                SizedBox(height: sizes.md),
              ],
              (null, VerifyEmailNotice.notConfirmedYet) => [
                AuthMessage(
                  text: l10n.notVerifiedYet,
                  tone: AuthMessageTone.error,
                ),
                SizedBox(height: sizes.md),
              ],
              (null, VerifyEmailNotice.none) => const <Widget>[],
            },
            GButton(
              label: l10n.verifiedAction,
              expand: true,
              isLoading: busy,
              onPressed: onCheck,
            ),
            SizedBox(height: sizes.sm),
            GButton.secondary(
              label: l10n.resendEmail,
              expand: true,
              onPressed: busy ? null : onResend,
            ),
            SizedBox(height: sizes.xs),
            GButton.text(
              label: l10n.verifyLater,
              expand: true,
              onPressed: onDone,
            ),
          ],
        ),
    };
  }
}
