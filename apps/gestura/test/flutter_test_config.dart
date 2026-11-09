import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';

const double crossPlatformAntiAliasingTolerance = 0.001;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
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
