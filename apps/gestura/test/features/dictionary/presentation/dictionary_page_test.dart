import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/localized_text.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/dictionary/presentation/pages/dictionary_page.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_state.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_view_model.dart';
import 'package:gestura/features/dictionary/presentation/widgets/dictionary_view.dart';
import 'package:gestura/features/dictionary/presentation/widgets/sign_tile.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/sign_detail/presentation/pages/sign_detail_page.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:gestura_ui/gestura_ui.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/pump_app.dart';

final String _dictionary = const DictionaryRoute().location;

const Duration _typingPause = Duration(milliseconds: 300);

List<String> _glosses(WidgetTester tester) => switch (tester
    .element(find.byType(DictionaryView))
    .read<DictionaryViewModel>()
    .state) {
  DictionaryLoaded(:final results) => [for (final sign in results) sign.gloss],
  _ => const [],
};

final Finder _list = find.descendant(
  of: find.byType(ListView),
  matching: find.byType(Scrollable),
);

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(_typingPause);
  await tester.pumpAndSettle();
}

ContentCatalog _withEmptyCategory() => ContentCatalog(
  pack: demoCatalog.pack,
  categories: [
    ...demoCatalog.categories,
    const SignCategory(
      id: CategoryId('food'),
      name: LocalizedText({'en': 'Food'}),
    ),
  ],
  courses: demoCatalog.courses,
  signs: demoCatalog.signs,
);

void main() {
  group('Dictionary', () {
    testWidgets('lists the signs by gloss with their meaning', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);

      final first = tester.widget<SignTile>(find.byType(SignTile).first);

      expect(first.sign.gloss, 'BROTHER');
      expect(find.text('BROTHER'), findsOneWidget);
      expect(find.text('Brother'), findsOneWidget);
      expect(find.byType(PlaceholderContentNotice), findsOneWidget);
      expect(find.text('12 signs'), findsOneWidget);
    });

    testWidgets('puts the signs under A to Z headings', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(initialLocation: _dictionary);

      expect(
        tester.getSemantics(find.text('B')),
        isSemantics(label: 'B', isHeader: true),
      );
      expect(find.text('F'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('searches every language after a short pause', (tester) async {
      await tester.pumpApp(
        initialLocation: _dictionary,
        settings: englishLight.copyWith(language: AppLanguage.german),
      );

      await tester.enterText(find.byType(TextField), 'Mutter');
      await tester.pump(const Duration(milliseconds: 100));

      expect(_glosses(tester), hasLength(demoCatalog.signs.length));

      await tester.pump(_typingPause);
      await tester.pumpAndSettle();

      expect(_glosses(tester), ['MOTHER']);
      expect(find.text('M'), findsNothing);
      expect(find.text('1 Gebärde'), findsOneWidget);
    });

    testWidgets('explains an empty search and clears it', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);

      await _search(tester, ' zebra ');

      expect(find.text('No signs for “zebra”'), findsOneWidget);
      expect(find.text('No signs'), findsNothing);

      await tester.tap(find.widgetWithText(GButton, 'Clear search'));
      await tester.pumpAndSettle();

      expect(_glosses(tester), hasLength(12));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('clears the field from its own button', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);

      expect(find.byTooltip('Clear search'), findsNothing);

      await _search(tester, 'yes');

      expect(_glosses(tester), ['YES']);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(_glosses(tester), hasLength(12));
      expect(find.byTooltip('Clear search'), findsNothing);
    });

    testWidgets('filters by category', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);

      await tester.tap(find.widgetWithText(GChip, 'Family'));
      await tester.pumpAndSettle();

      expect(_glosses(tester), [
        'BROTHER',
        'FAMILY',
        'FATHER',
        'FRIEND',
        'MOTHER',
        'SISTER',
      ]);

      await tester.tap(find.widgetWithText(GChip, 'Family'));
      await tester.pumpAndSettle();

      expect(_glosses(tester), hasLength(12));

      await tester.tap(find.widgetWithText(GChip, 'Greetings'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GChip, 'All'));
      await tester.pumpAndSettle();

      expect(_glosses(tester), hasLength(12));
    });

    testWidgets('says when a category has no signs yet', (tester) async {
      await tester.pumpApp(
        initialLocation: _dictionary,
        content: FakeContentRepository(catalog: _withEmptyCategory()),
      );

      await tester.ensureVisible(find.widgetWithText(GChip, 'Food'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GChip, 'Food'));
      await tester.pumpAndSettle();

      expect(find.text('No signs in this category yet'), findsOneWidget);

      await tester.tap(find.widgetWithText(GButton, 'All'));
      await tester.pumpAndSettle();

      expect(_glosses(tester), hasLength(12));
    });

    testWidgets('opens a sign and keeps the search on the way back', (
      tester,
    ) async {
      await tester.pumpApp(initialLocation: _dictionary);
      await _search(tester, 'hel');

      await tester.tap(find.text('HELLO'));
      await tester.pumpAndSettle();

      expect(find.byType(SignDetailPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(DictionaryPage), findsOneWidget);
      expect(_glosses(tester), ['HELLO']);
    });

    testWidgets('flies the thumbnail into the sign page', (tester) async {
      final content = FakeContentRepository();
      await tester.pumpApp(initialLocation: _dictionary, content: content);
      final shuttle = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.width == null &&
            widget.image ==
                const AssetImage('assets/content/demo/media/brother.webp'),
      );

      expect(shuttle, findsNothing);

      final hold = content.hold = Completer<void>();
      await tester.tap(find.text('BROTHER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(shuttle, findsOneWidget);
      expect(find.byType(GSkeleton), findsWidgets);

      final route = ModalRoute.of(tester.element(find.byType(SignDetailPage)))!;
      expect(route.settings, isA<MaterialPage<void>>());
      expect(
        (route as PageRoute<void>).transitionDuration,
        greaterThan(Duration.zero),
      );

      hold.complete();
      await tester.pumpAndSettle();

      expect(find.byType(SignDetailPage), findsOneWidget);
    });

    testWidgets('skips the flight under reduce motion', (tester) async {
      await tester.pumpApp(
        initialLocation: _dictionary,
        settings: englishLight.copyWith(reduceMotion: true),
      );

      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('waits for the learner to stop typing', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);
      final viewModel = tester
          .element(find.byType(SignTile).first)
          .read<DictionaryViewModel>();

      expect(viewModel.debounce, DictionaryViewModel.searchDebounce);
    });

    testWidgets('reaches every sign', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);

      final glosses = [for (final sign in demoCatalog.signs) sign.gloss]
        ..sort();

      for (final gloss in glosses) {
        await tester.scrollUntilVisible(
          find.text(gloss),
          100,
          scrollable: _list,
        );
        expect(find.text(gloss), findsOneWidget);
      }
    });

    testWidgets('shows each meaning in the interface language', (tester) async {
      await tester.pumpApp(
        initialLocation: _dictionary,
        settings: englishLight.copyWith(language: AppLanguage.german),
      );

      expect(find.text('Bruder'), findsOneWidget);
    });

    testWidgets('shows the thumbnail of each sign, hidden from screen '
        'readers', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);

      final image = tester.widget<Image>(
        find.descendant(
          of: find.byType(SignTile).first,
          matching: find.byType(Image),
        ),
      );

      expect(
        (image.image as ResizeImage).imageProvider,
        isA<AssetImage>().having(
          (asset) => asset.assetName,
          'asset',
          'assets/content/demo/media/brother.webp',
        ),
      );
      expect(image.excludeFromSemantics, isTrue);
    });

    testWidgets('keeps the row when a thumbnail is missing', (tester) async {
      await tester.pumpApp(initialLocation: _dictionary);
      final image = tester.widget<Image>(find.byType(Image).first);

      final fallback = image.errorBuilder!(
        tester.element(find.byType(Image).first),
        StateError('missing'),
        null,
      );

      expect(fallback, isA<ColoredBox>());
    });

    testWidgets('explains a failure and tries again', (tester) async {
      final content = FakeContentRepository()..failure = const NetworkFailure();
      await tester.pumpApp(initialLocation: _dictionary, content: content);

      expect(find.byType(GErrorView), findsOneWidget);
      expect(
        find.text("You're offline. Check your connection and try again."),
        findsOneWidget,
      );

      content.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(SignTile), findsWidgets);
      expect(content.requests, 4);
    });

    for (final settings in [
      englishLight,
      const AppSettings(
        language: AppLanguage.arabic,
        theme: AppThemePreference.dark,
        onboardingComplete: true,
      ),
    ]) {
      testWidgets('meets the accessibility guidelines in '
          '${settings.language.name} ${settings.theme.name}', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpApp(settings: settings, initialLocation: _dictionary);

        await tester.expectAccessible();
        handle.dispose();
      });
    }

    testWidgets('fits at 200% text on a small phone', (tester) async {
      await tester.pumpApp(
        initialLocation: _dictionary,
        surfaceSize: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
