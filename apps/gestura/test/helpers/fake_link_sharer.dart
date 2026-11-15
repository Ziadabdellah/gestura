import 'dart:ui';

import 'package:gestura/core/share/link_sharer.dart';

class FakeLinkSharer implements LinkSharer {
  final List<(Uri, String, Rect?)> shared = [];
  final List<(String, String)> files = [];

  @override
  Future<void> share(Uri link, {required String subject, Rect? origin}) async =>
      shared.add((link, subject, origin));

  @override
  Future<void> shareFile(
    String path, {
    required String subject,
    Rect? origin,
  }) async => files.add((path, subject));
}
