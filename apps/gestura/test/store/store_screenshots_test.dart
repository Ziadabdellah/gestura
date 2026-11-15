@Tags(['store'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';

import '../helpers/fake_activity_repository.dart';
import '../helpers/fake_progress_repository.dart';
import '../helpers/fake_review_repository.dart';
import '../helpers/pump_app.dart';

const Map<String, String> _screens = {
  '1_today': '/today',
  '2_learn': '/learn',
  '3_sign': '/dictionary/sign/thank-you',
  '4_dictionary': '/dictionary',
  '5_alphabet': '/dictionary/alphabet',
  '6_progress': '/profile/progress',
};

void main() {
  setUpAll(loadFonts);

  for (final language in [AppLanguage.english, AppLanguage.arabic]) {
    for (final MapEntry(key: name, value: location) in _screens.entries) {
      testWidgets('${language.code} $name', (tester) async {
        final today = DateTime.now();
        final reviews = FakeReviewRepository();
        await reviews.addSigns({
          for (final id in ['hello', 'thank-you', 'please', 'yes', 'no'])
            SignId(id),
        });
        await tester.pumpApp(
          initialLocation: location,
          settings: AppSettings(
            language: language,
            theme: AppThemePreference.light,
            onboardingComplete: true,
          ),
          progress: FakeProgressRepository([
            completed('demo-a1-1', score: 100),
            completed('demo-a1-2'),
          ]),
          reviews: reviews,
          activity: FakeActivityRepository([
            for (var day = 0; day < 5; day++)
              DailyActivity(
                day: DateTime(today.year, today.month, today.day - day),
                lessons: 1,
                reviews: 6,
                seconds: 420,
              ),
          ]),
        );
        await precacheImages(tester);
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(GesturaApp),
          matchesGoldenFile(
            '../../store/screenshots/${language.code}/$name.png',
          ),
        );
      });
    }
  }
}
