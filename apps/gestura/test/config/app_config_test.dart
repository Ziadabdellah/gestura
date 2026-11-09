import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_config.dart';

void main() {
  group('Flavor', () {
    test('reads each flavor from its name', () {
      for (final flavor in Flavor.values) {
        expect(Flavor.fromName(flavor.name), flavor);
      }
    });

    test('falls back to dev for an unknown or missing name', () {
      expect(Flavor.fromName('qa'), Flavor.dev);
      expect(Flavor.fromName(null), Flavor.dev);
    });
  });

  group('AppConfig', () {
    test('is production only for the prod flavor', () {
      expect(const AppConfig(flavor: Flavor.prod).isProd, isTrue);
      expect(const AppConfig(flavor: Flavor.staging).isProd, isFalse);
      expect(const AppConfig(flavor: Flavor.dev).isProd, isFalse);
    });

    test('compares by flavor', () {
      final flavor = Flavor.fromName('staging');

      expect(
        AppConfig(flavor: flavor),
        const AppConfig(flavor: Flavor.staging),
      );
      expect(
        AppConfig(flavor: flavor).hashCode,
        const AppConfig(flavor: Flavor.staging).hashCode,
      );
      expect(
        const AppConfig(flavor: Flavor.dev),
        isNot(const AppConfig(flavor: Flavor.prod)),
      );
    });
  });
}
