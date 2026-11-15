import 'package:flutter/material.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.linkOpenFailed;
  bool opened;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } on Object {
    opened = false;
  }
  if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
}
