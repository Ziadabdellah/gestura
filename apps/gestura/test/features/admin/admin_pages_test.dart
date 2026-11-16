import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';
import 'package:gestura/features/admin/presentation/pages/admin_home_page.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/profile/presentation/pages/profile_page.dart';
import 'package:gestura/features/today/presentation/pages/today_page.dart';

import '../../helpers/fake_admin.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

const MemberUser _admin = MemberUser(
  'admin-uid',
  email: 'admin@gestura.app',
  emailVerified: true,
);

extension on WidgetTester {
  Future<void> fill(String label, String text) async {
    final field = find.widgetWithText(TextFormField, label);
    await scrollUntilVisible(
      field,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await enterText(field, text);
  }

  Future<void> save() async {
    await tap(find.text('Save'));
    await pumpAndSettle();
  }
}

void main() {
  late FakeContentStore store;

  setUp(() {
    store = FakeContentStore();
    store.docs[ContentKind.signLanguages]!['ase'] = {
      'name': {'en': 'ASL'},
      'published': true,
    };
    store.docs[ContentKind.categories]!['greetings'] = {
      'name': {'en': 'Greetings'},
      'published': false,
    };
  });

  testWidgets('an admin signing in lands on the dashboard', (tester) async {
    final auth = FakeAuthRepository(null);
    await tester.pumpApp(
      auth: auth,
      store: store,
      admin: FakeAdminAccess({'learner@example.com'}),
      initialLocation: '/account/sign-in?entry=welcome',
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'learner@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(AdminHomePage), findsOneWidget);
    expect(find.text('Sign languages'), findsOneWidget);
    expect(find.textContaining('1 item'), findsNWidgets(2));
  });

  testWidgets('goes from the dashboard to a new item and back', (tester) async {
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin',
    );
    await tester.tap(find.text('Sign languages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'ID'), 'bsl');
    await tester.fill('English', 'BSL');
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('twoHanded').last);
    await tester.pumpAndSettle();
    await tester.fill('Order', '1');
    await tester.save();

    expect(find.text('BSL'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('learners never reach the dashboard', (tester) async {
    await tester.pumpApp(store: store, initialLocation: '/admin');

    expect(find.byType(AdminHomePage), findsNothing);
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Open the admin dashboard'), findsNothing);
  });

  testWidgets('the profile opens the dashboard for an admin', (tester) async {
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/profile',
    );
    await tester.tap(find.text('Open the admin dashboard'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminHomePage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('adds, edits, searches and deletes a category', (tester) async {
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin/categories',
    );
    expect(find.text('Greetings'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.save();
    expect(find.text('Letters, numbers and - only'), findsOneWidget);
    expect(find.text('Required'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextFormField, 'ID'), 'family');
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ase').last);
    await tester.pumpAndSettle();
    await tester.fill('English', 'Family');
    await tester.fill('Arabic', 'العائلة');
    await tester.fill('Order', '2');
    await tester.save();

    expect(store.docs[ContentKind.categories]!['family'], {
      'signLanguage': 'ase',
      'name': {'en': 'Family', 'ar': 'العائلة'},
      'order': 2,
      'published': true,
    });
    expect(find.text('Family'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'fam');
    await tester.pumpAndSettle();
    expect(find.text('Greetings'), findsNothing);

    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(find.text('Edit · family'), findsOneWidget);
    await tester.fill('English', 'Families');
    await tester.save();
    expect(find.text('Families'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.docs[ContentKind.categories], contains('family'));

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(store.docs[ContentKind.categories], isNot(contains('family')));
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('checks sign fields and reports a failed save', (tester) async {
    store.docs[ContentKind.signs]!['hello'] = sampleSign;
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin/signs/edit/hello',
    );
    await tester.fill('Video path', 'bad path');
    await tester.fill('Duration (ms)', '0');
    await tester.save();
    expect(
      find.text('Starts with media/ or asset/, no spaces'),
      findsOneWidget,
    );
    expect(find.text('Whole number in range'), findsOneWidget);

    store.fail = true;
    await tester.fill('Video path', 'media/hi.mp4');
    await tester.fill('Duration (ms)', '1000');
    await tester.save();
    expect(
      find.text('Not saved. Check the fields and your connection.'),
      findsOneWidget,
    );
  });

  testWidgets('edits choices, toggles and JSON lists', (tester) async {
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin/signLanguages/edit/ase',
    );
    await tester.tap(find.text('Placeholder content'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('twoHanded').last);
    await tester.pumpAndSettle();
    await tester.fill('Order', '0');
    await tester.save();
    expect(store.docs[ContentKind.signLanguages]!['ase'], {
      'name': {'en': 'ASL'},
      'fingerspelling': 'twoHanded',
      'placeholder': true,
      'order': 0,
      'published': true,
    });
    expect(find.text('ASL'), findsOneWidget);
  });

  testWidgets('checks JSON lists', (tester) async {
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin/courses/new',
    );
    await tester.fill('Units (JSON list)', '[{"index": 1}');
    await tester.save();
    expect(find.text('A JSON list that is not empty'), findsOneWidget);
  });

  testWidgets('shows lesson steps', (tester) async {
    store.docs[ContentKind.lessons]!['l1'] = {
      'courseId': 'c1',
      'unit': 1,
      'order': 0,
      'title': {'en': 'Hello'},
      'steps': [
        {'type': 'learn', 'sign': 'hello'},
      ],
      'published': false,
    };
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin/lessons/edit/l1',
    );
    expect(find.text('c1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('"learn"'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  });

  testWidgets('opens a missing item empty', (tester) async {
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin/lessons/edit/missing',
    );
    expect(find.text('Edit · missing'), findsOneWidget);
  });

  testWidgets('explains an item that fails to load', (tester) async {
    store
      ..failWatch = true
      ..fail = true;
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin/lessons/edit/l1',
    );
    expect(find.text("Couldn't load the content."), findsOneWidget);
  });

  testWidgets('retries a collection that failed', (tester) async {
    store.failWatch = true;
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin/lessons',
    );
    expect(find.text("Couldn't load the content."), findsOneWidget);
    store.failWatch = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('sends unknown kinds back to the dashboard', (tester) async {
    await tester.pumpApp(
      auth: FakeAuthRepository(_admin),
      store: store,
      initialLocation: '/admin/nope',
    );
    expect(find.byType(AdminHomePage), findsOneWidget);
    expect(find.byType(TodayPage), findsNothing);
  });
}
