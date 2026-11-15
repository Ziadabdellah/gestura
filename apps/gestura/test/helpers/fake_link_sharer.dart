import 'dart:ui';

import 'package:gestura/core/share/link_sharer.dart';

class FakeLinkSharer implements LinkSharer {
  final List<(Uri, String, Rect?)> shared = [];

  @override
  Future<void> share(Uri link, {required String subject, Rect? origin}) async =>
      shared.add((link, subject, origin));
}
