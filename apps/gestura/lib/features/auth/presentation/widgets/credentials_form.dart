import 'package:flutter/material.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_state.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_fields.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_message.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

typedef CredentialsSubmit = void Function(String email, String password);

class CredentialsForm extends StatefulWidget {
  const new({
    required this.state,
    required this.submitLabel,
    required this.onSubmit,
    super.key,
    this.isNewPassword = false,
    this.belowPassword,
    this.footer = const [],
  });

  final AuthFormState state;
  final String submitLabel;
  final CredentialsSubmit onSubmit;
  final bool isNewPassword;
  final Widget? belowPassword;
  final List<Widget> footer;

  @override
  State<CredentialsForm> createState() => _CredentialsFormState();
}

class _CredentialsFormState extends State<CredentialsForm> {
  final GlobalKey<FormState> _form = GlobalKey();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  AutovalidateMode _validation = AutovalidateMode.disabled;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.state is AuthFormBusy) return;
    if (_form.currentState?.validate() ?? false) {
      widget.onSubmit(_email.text, _password.text);
    } else {
      setState(() => _validation = AutovalidateMode.onUserInteraction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final state = widget.state;
    final below = widget.belowPassword;

    return Form(
      key: _form,
      autovalidateMode: _validation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmailField(controller: _email),
                SizedBox(height: sizes.md),
                PasswordField(
                  controller: _password,
                  isNew: widget.isNewPassword,
                  onSubmitted: _submit,
                ),
              ],
            ),
          ),
          ?below,
          SizedBox(height: sizes.md),
          if (state case AuthFormFailed(:final failure)) ...[
            AuthMessage.failure(failure, l10n: l10n),
            SizedBox(height: sizes.md),
          ],
          GButton(
            label: widget.submitLabel,
            expand: true,
            isLoading: state is AuthFormBusy,
            onPressed: _submit,
          ),
          ...widget.footer,
        ],
      ),
    );
  }
}
