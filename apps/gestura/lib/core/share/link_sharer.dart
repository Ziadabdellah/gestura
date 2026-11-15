import 'dart:ui';

import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

const String linkSite = 'https://gestura-prod.web.app';

Uri signLink(SignId sign) => Uri.parse('$linkSite/sign/${sign.value}');

abstract interface class LinkSharer {
  Future<void> share(Uri link, {required String subject, Rect? origin});
}

@LazySingleton(as: LinkSharer)
final class SystemLinkSharer implements LinkSharer {
  const new();

  @override
  Future<void> share(Uri link, {required String subject, Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(uri: link, subject: subject, sharePositionOrigin: origin),
    );
  }
}
