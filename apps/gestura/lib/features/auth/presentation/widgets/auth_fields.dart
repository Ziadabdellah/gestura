import 'package:flutter/material.dart';
import 'package:gestura/features/auth/domain/credentials.dart';
import 'package:gestura/l10n/l10n.dart';

class EmailField extends StatelessWidget {
  const new({
    required this.controller,
    super.key,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.email],
      onFieldSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: l10n.emailLabel,
        prefixIcon: const ExcludeSemantics(child: Icon(Icons.mail_outline)),
      ),
      validator: (value) => switch (Credentials.checkEmail(value ?? '')) {
        EmailProblem.missing => l10n.emailRequired,
        EmailProblem.invalid => l10n.emailInvalid,
        null => null,
      },
    );
  }
}

class PasswordField extends StatefulWidget {
  const new({
    required this.controller,
    required this.onSubmitted,
    super.key,
    this.isNew = false,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool isNew;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: [
        if (widget.isNew) AutofillHints.newPassword else AutofillHints.password,
      ],
      onFieldSubmitted: (_) => widget.onSubmitted(),
      decoration: InputDecoration(
        labelText: l10n.passwordLabel,
        helperText: widget.isNew
            ? l10n.passwordHint(Credentials.minPasswordLength)
            : null,
        prefixIcon: const ExcludeSemantics(child: Icon(Icons.lock_outline)),
        suffixIcon: IconButton(
          tooltip: _visible ? l10n.hidePassword : l10n.showPassword,
          onPressed: () => setState(() => _visible = !_visible),
          icon: Icon(
            _visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: (value) =>
          switch (Credentials.checkPassword(value ?? '', isNew: widget.isNew)) {
            PasswordProblem.missing => l10n.passwordRequired,
            PasswordProblem.tooShort => l10n.passwordTooShort(
              Credentials.minPasswordLength,
            ),
            null => null,
          },
    );
  }
}
