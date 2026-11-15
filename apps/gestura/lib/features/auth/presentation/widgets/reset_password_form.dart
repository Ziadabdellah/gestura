import 'package:flutter/material.dart';
import 'package:gestura/features/auth/domain/credentials.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_state.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_fields.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_message.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class ResetPasswordForm extends StatefulWidget {
  const new({
    required this.state,
    required this.onSubmit,
    required this.onBackToSignIn,
    super.key,
  });

  final AuthFormState state;
  final ValueChanged<String> onSubmit;
  final VoidCallback onBackToSignIn;

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final GlobalKey<FormState> _form = GlobalKey();
  final TextEditingController _email = TextEditingController();
  AutovalidateMode _validation = AutovalidateMode.disabled;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.state is AuthFormBusy) return;
    if (_form.currentState?.validate() ?? false) {
      widget.onSubmit(_email.text);
    } else {
      setState(() => _validation = AutovalidateMode.onUserInteraction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final state = widget.state;

    if (state is AuthFormDone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthMessage(
            text: l10n.resetLinkSent(Credentials.normalizeEmail(_email.text)),
            tone: AuthMessageTone.success,
          ),
          SizedBox(height: sizes.lg),
          GButton(
            label: l10n.backToSignIn,
            expand: true,
            onPressed: widget.onBackToSignIn,
          ),
        ],
      );
    }

    return Form(
      key: _form,
      autovalidateMode: _validation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutofillGroup(
            child: EmailField(
              controller: _email,
              textInputAction: TextInputAction.send,
              onSubmitted: _submit,
            ),
          ),
          SizedBox(height: sizes.md),
          if (state case AuthFormFailed(:final failure)) ...[
            AuthMessage.failure(failure, l10n: l10n),
            SizedBox(height: sizes.md),
          ],
          GButton(
            label: l10n.sendResetLink,
            expand: true,
            isLoading: state is AuthFormBusy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
