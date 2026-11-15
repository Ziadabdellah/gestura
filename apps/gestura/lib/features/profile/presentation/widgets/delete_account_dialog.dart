import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

typedef DeleteConfirmation = ({String? password});

Future<DeleteConfirmation?> confirmDeleteAccount(
  BuildContext context, {
  required bool needsPassword,
}) => showDialog<DeleteConfirmation>(
  context: context,
  builder: (context) => DeleteAccountDialog(needsPassword: needsPassword),
);

class DeleteAccountDialog extends StatefulWidget {
  const new({required this.needsPassword, super.key});

  final bool needsPassword;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop<DeleteConfirmation>((
    password: widget.needsPassword ? _password.text : null,
  ));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.deleteAccountMessage),
            if (widget.needsPassword) ...[
              SizedBox(height: sizes.md),
              Text(l10n.deleteAccountPasswordPrompt),
              SizedBox(height: sizes.xs),
              TextField(
                controller: _password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ValueListenableBuilder(
          valueListenable: _password,
          builder: (context, value, _) => TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: widget.needsPassword && value.text.isEmpty
                ? null
                : _confirm,
            child: Text(l10n.deleteAction),
          ),
        ),
      ],
    );
  }
}
