import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/admin/domain/content_doc.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';
import 'package:gestura/features/admin/presentation/view_models/admin_access_view_model.dart';
import 'package:gestura/features/admin/presentation/view_models/collection_cubit.dart';
import 'package:gestura/features/admin/presentation/view_models/editor_cubit.dart';
import 'package:gestura/features/auth/domain/app_user.dart';

import '../../helpers/fake_admin.dart';
import '../../helpers/fake_auth_repository.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('AdminAccessViewModel', () {
    test('follows the signed-in user', () async {
      final auth = FakeAuthRepository(null);
      final viewModel = AdminAccessViewModel(
        auth,
        FakeAdminAccess({'admin@example.com'}),
      );
      auth.user = const MemberUser(
        'a',
        email: 'admin@example.com',
        emailVerified: true,
      );
      await settle();
      expect(viewModel.state, isTrue);

      auth.user = const MemberUser(
        'a',
        email: 'admin@example.com',
        emailVerified: false,
      );
      await settle();
      expect(viewModel.state, isFalse);
      await viewModel.close();
    });
  });

  group('CollectionCubit', () {
    late FakeContentStore store;

    setUp(() {
      store = FakeContentStore();
      store.docs[ContentKind.signs]!
        ..['hello'] = sampleSign
        ..['bye'] = {...sampleSign, 'gloss': 'BYE'};
    });

    test('lists, searches, follows changes and deletes', () async {
      final cubit = CollectionCubit(store, ContentKind.signs)..load();
      await settle();
      final ready = cubit.state as CollectionReady;
      expect(ready.visible(ContentKind.signs).map((d) => d.id), [
        'bye',
        'hello',
      ]);

      cubit.search('hel');
      await settle();
      expect((cubit.state as CollectionReady).visible(ContentKind.signs), [
        const ContentDoc('hello', sampleSign),
      ]);
      cubit.search('BYE');
      expect(
        (cubit.state as CollectionReady).visible(ContentKind.signs).single.id,
        'bye',
      );

      expect(await cubit.delete('bye'), isTrue);
      await settle();
      final after = cubit.state as CollectionReady;
      expect(after.all, hasLength(1));
      expect(after.query, 'BYE');

      store.fail = true;
      expect(await cubit.delete('hello'), isFalse);
      await cubit.close();
    });

    test('fails when the collection cannot be read', () async {
      store.failWatch = true;
      final cubit = CollectionCubit(store, ContentKind.signs)
        ..search('ignored')
        ..load();
      await settle();
      expect(cubit.state, const CollectionFailed());
      expect(const CollectionLoading().props, isEmpty);
      await cubit.close();
    });
  });

  group('EditorCubit', () {
    late FakeContentStore store;

    setUp(() => store = FakeContentStore());

    test('validates before saving a new category', () async {
      final cubit = EditorCubit(store, ContentKind.categories);
      expect(cubit.isNew, isTrue);

      await cubit.save();
      expect(cubit.state.idError, IdError.format);
      expect(cubit.state.errors.keys, contains(FieldName.name));

      cubit
        ..setId(' family ')
        ..setValue(FieldName.signLanguage, 'ase')
        ..setValue(FieldName.name, {'en': 'Family'})
        ..setValue(FieldName.order, '1')
        ..setPublished(published: true);
      expect(cubit.state.errors, isEmpty);
      await cubit.save();

      expect(cubit.state.status, EditorStatus.saved);
      expect(store.docs[ContentKind.categories]!['family'], {
        'signLanguage': 'ase',
        'name': {'en': 'Family'},
        'order': 1,
        'published': true,
      });
    });

    test('refuses an ID that is taken and reports failures', () async {
      store.docs[ContentKind.signs]!['hello'] = sampleSign;
      final cubit = EditorCubit(store, ContentKind.signs)..setId('hello');
      for (final MapEntry(:key, :value) in EditorCubit(
        store,
        ContentKind.signs,
        existing: const ContentDoc('hello', sampleSign),
      ).state.values.entries) {
        final field = FieldName.values.where((f) => f.name == key);
        if (field.isNotEmpty) cubit.setValue(field.single, value);
      }
      await cubit.save();
      expect(cubit.state.idError, IdError.taken);
      expect(cubit.state.status, EditorStatus.editing);

      cubit.setId('hello-2');
      store.fail = true;
      await cubit.save();
      expect(cubit.state.status, EditorStatus.failed);
    });

    test('updates an existing sign in place', () async {
      final cubit = EditorCubit(
        store,
        ContentKind.signs,
        existing: const ContentDoc('hello', sampleSign),
      );
      expect(cubit.isNew, isFalse);
      cubit.setValue(FieldName.gloss, 'HI');
      await cubit.save();
      expect(store.calls, ['save signs/hello']);
      expect(store.docs[ContentKind.signs]!['hello']!['gloss'], 'HI');
    });

    test('reads JSON lists', () {
      expect(parseJsonList('[1, 2]'), [1, 2]);
      expect(parseJsonList('[1,'), isNull);
    });
  });
}
