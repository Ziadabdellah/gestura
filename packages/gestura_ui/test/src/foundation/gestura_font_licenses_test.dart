import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

class _FakeBundle extends CachingAssetBundle {
  final requested = <String>[];

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    requested.add(key);
    return 'Licence text for $key';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(LicenseRegistry.reset);

  test('registers the OFL licence of every bundled font', () async {
    final bundle = _FakeBundle();
    GesturaFontLicenses.register(bundle: bundle);

    final entries = await LicenseRegistry.licenses.toList();
    final packages = entries.expand((entry) => entry.packages).toList();

    expect(packages, containsAll(['Readex Pro', 'Golos Text']));
    expect(bundle.requested, [
      'packages/gestura_ui/assets/licenses/OFL-ReadexPro.txt',
      'packages/gestura_ui/assets/licenses/OFL-GolosText.txt',
    ]);
  });

  test('loads the bundled OFL texts from the root bundle by default', () async {
    GesturaFontLicenses.register();

    final entries = await LicenseRegistry.licenses.toList();
    final texts = {
      for (final entry in entries)
        entry.packages.single: entry.paragraphs.map((p) => p.text).join(' '),
    };

    expect(texts.keys, ['Readex Pro', 'Golos Text']);
    for (final text in texts.values) {
      expect(text, contains('SIL Open Font License, Version 1.1'));
    }
  });
}
