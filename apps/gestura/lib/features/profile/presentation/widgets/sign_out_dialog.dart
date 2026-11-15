import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';

Future<bool> confirmSignOut(BuildContext context) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.signOutTitle),
      content: Text(l10n.signOutMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.signOut),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
