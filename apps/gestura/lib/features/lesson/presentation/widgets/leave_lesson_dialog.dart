import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';

Future<bool> confirmLeaveLesson(BuildContext context) async {
  final l10n = context.l10n;
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.leaveLessonTitle),
      content: Text(l10n.leaveLessonMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.leaveLessonStay),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.leaveLessonLeave),
        ),
      ],
    ),
  );
  return leave ?? false;
}
