import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura_ui/gestura_ui.dart';

const double crossPlatformAntiAliasingTolerance = 0.001;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFontsUnderPackageNames();
  final isCi = Platform.environment.containsKey('CI');
  await AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isCi),
      ciGoldensConfig: const CiGoldensConfig(
        diffThreshold: crossPlatformAntiAliasingTolerance,
      ),
    ),
    run: testMain,
  );
}

Future<void> _loadFontsUnderPackageNames() async {
  const families = {GesturaFonts.readexPro, GesturaFonts.golosText};
  final manifest = await rootBundle.loadString('FontManifest.json');
  final entries = (jsonDecode(manifest) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  for (final entry in entries) {
    final family = entry['family'] as String;
    if (!families.contains(family)) continue;
    final loader = FontLoader('packages/${GesturaFonts.package}/$family');
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}
