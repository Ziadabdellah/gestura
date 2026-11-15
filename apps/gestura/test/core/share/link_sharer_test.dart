import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/share/link_sharer.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class _FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  final List<ShareParams> shared = [];

  @override
  Future<ShareResult> share(ShareParams params) async {
    shared.add(params);
    return const ShareResult('', ShareResultStatus.success);
  }
}

void main() {
  test('builds the public link of a sign', () {
    expect(
      signLink(const SignId('thank-you')).toString(),
      'https://gestura-prod.web.app/sign/thank-you',
    );
  });

  test('hands the link to the system share sheet', () async {
    final platform = _FakeSharePlatform();
    SharePlatform.instance = platform;
    const origin = Rect.fromLTWH(1, 2, 3, 4);

    await const SystemLinkSharer().share(
      signLink(const SignId('hello')),
      subject: 'HELLO',
      origin: origin,
    );

    final params = platform.shared.single;
    expect(params.uri.toString(), 'https://gestura-prod.web.app/sign/hello');
    expect(params.subject, 'HELLO');
    expect(params.sharePositionOrigin, origin);
  });
}
