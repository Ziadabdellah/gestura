import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseAuth get auth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseFirestore get firestore =>
      FirebaseFirestore.instance
        ..settings = const Settings(persistenceEnabled: false);

  @LazySingleton(env: ['prod'])
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  @LazySingleton(env: ['prod'])
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  @LazySingleton(env: ['prod'])
  FirebaseRemoteConfig get remoteConfig => FirebaseRemoteConfig.instance;

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn.instance;
}
