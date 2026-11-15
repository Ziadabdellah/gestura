import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/core/media/media_image.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/sign.dart';

import '../../helpers/fake_media_cache.dart';

final Uri _remote = Uri.parse(
  'https://c.web.app/content/demo/media/hello.webp',
);

Future<void> _pump(WidgetTester tester, MediaRef media) => tester.pumpWidget(
  MaterialApp(home: MediaImage(media: media, width: 40, height: 50)),
);

void main() {
  late FakeMediaCache cache;

  setUp(() async {
    await getIt.reset();
    cache = FakeMediaCache('assets/content/demo/media');
    getIt.registerSingleton<MediaCache>(cache);
  });

  tearDown(getIt.reset);

  testWidgets('shows a bundled image from the app', (tester) async {
    await _pump(
      tester,
      const AssetMedia('assets/content/demo/media/hello.webp'),
    );

    expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
  });

  testWidgets('shows a downloaded image from the device', (tester) async {
    await _pump(tester, RemoteMedia(_remote));

    expect(find.byType(Image), findsNothing);
    expect(find.byType(ColoredBox), findsWidgets);

    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(tester.widget<Image>(find.byType(Image)).image, isA<FileImage>());
    expect(cache.requested, [_remote]);
  });

  testWidgets('downloads again only when the address changes', (tester) async {
    await _pump(tester, RemoteMedia(_remote));
    await _pump(tester, RemoteMedia(_remote));
    await _pump(tester, RemoteMedia(_remote.resolve('thank-you.webp')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(cache.requested, hasLength(2));
  });

  testWidgets('keeps the space when an image cannot be read', (tester) async {
    await _pump(tester, const AssetMedia('assets/nothing-here.webp'));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));

    final fallback = image.errorBuilder!(
      tester.element(find.byType(Image)),
      const FileSystemException('missing'),
      null,
    );

    expect(fallback, isA<ColoredBox>());

    await _pump(tester, RemoteMedia(_remote));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    final file = tester.widget<Image>(find.byType(Image));
    expect(
      file.errorBuilder!(
        tester.element(find.byType(Image)),
        const FileSystemException('missing'),
        null,
      ),
      isA<ColoredBox>(),
    );
  });
}
