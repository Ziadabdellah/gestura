import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_content_repository.dart';
import '../../helpers/fake_media_cache.dart';
import '../../helpers/pump_app.dart';

class _RemoteContent extends FakeContentRepository {
  @override
  Future<Result<List<Sign>>> searchSigns(String query) async => Ok([
    for (final sign in demoCatalog.signs.take(1))
      Sign(
        id: sign.id,
        gloss: sign.gloss,
        meaning: sign.meaning,
        category: sign.category,
        media: SignMedia(
          video: RemoteMedia(Uri.parse('https://c.web.app/m/a.mp4')),
          thumbnail: RemoteMedia(Uri.parse('https://c.web.app/m/a.webp')),
          duration: sign.media.duration,
        ),
        source: sign.source,
      ),
  ]);
}

void main() {
  testWidgets('downloads the signs from the profile', (tester) async {
    await tester.pumpApp(
      initialLocation: '/profile',
      content: _RemoteContent(),
    );
    final cache = getIt<MediaCache>() as FakeMediaCache;

    expect(find.text('0 of 2 files saved'), findsOneWidget);

    await tester.tap(find.text('Download signs for offline use'));
    await tester.pumpAndSettle();

    expect(cache.stored, hasLength(2));
    expect(
      find.text('Saved on this phone, works without internet'),
      findsOneWidget,
    );
  });

  testWidgets('shows progress and offers a retry', (tester) async {
    await tester.pumpApp(
      initialLocation: '/profile',
      content: _RemoteContent(),
    );
    final cache = getIt<MediaCache>() as FakeMediaCache..missing.add('a.mp4');
    final hold = cache.hold = Completer<void>();

    await tester.tap(find.text('Download signs for offline use'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    hold.complete();
    cache.hold = null;
    await tester.pumpAndSettle();

    expect(find.textContaining('Tap to try the rest again'), findsOneWidget);
    cache.missing.clear();
    await tester.tap(find.text('Download signs for offline use'));
    await tester.pumpAndSettle();
    expect(
      find.text('Saved on this phone, works without internet'),
      findsOneWidget,
    );
  });

  testWidgets('stays hidden for bundled content', (tester) async {
    await tester.pumpApp(initialLocation: '/profile');

    expect(find.text('Download signs for offline use'), findsNothing);
  });
}
