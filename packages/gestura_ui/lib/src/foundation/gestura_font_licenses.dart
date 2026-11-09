import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class GesturaFontLicenses {
  static const Map<String, String> _files = {
    'Readex Pro': 'packages/gestura_ui/assets/licenses/OFL-ReadexPro.txt',
    'Golos Text': 'packages/gestura_ui/assets/licenses/OFL-GolosText.txt',
  };

  static void register({AssetBundle? bundle}) {
    final source = bundle ?? rootBundle;
    LicenseRegistry.addLicense(() => _entries(source));
  }

  static Stream<LicenseEntry> _entries(AssetBundle source) async* {
    for (final MapEntry(key: font, value: path) in _files.entries) {
      yield LicenseEntryWithLineBreaks([font], await source.loadString(path));
    }
  }
}
