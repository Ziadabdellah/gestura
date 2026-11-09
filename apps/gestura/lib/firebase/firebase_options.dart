import 'package:firebase_core/firebase_core.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/firebase/firebase_options_dev.dart' as dev;
import 'package:gestura/firebase/firebase_options_prod.dart' as prod;
import 'package:gestura/firebase/firebase_options_staging.dart' as staging;

FirebaseOptions firebaseOptionsFor(Flavor flavor) => switch (flavor) {
  Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
  Flavor.staging => staging.DefaultFirebaseOptions.currentPlatform,
  Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
};
