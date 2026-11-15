import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/firebase/firebase_options.dart';

const String authEmulatorHost = String.fromEnvironment(
  'AUTH_EMULATOR_HOST',
  defaultValue: 'localhost',
);
const int authEmulatorPort = 9099;
const int firestoreEmulatorPort = 8080;

bool _connected = false;

Future<FirebaseAuth> emulatedAuth() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: firebaseOptionsFor(Flavor.dev));
  }
  final auth = FirebaseAuth.instance;
  if (!_connected) {
    await auth.useAuthEmulator(authEmulatorHost, authEmulatorPort);
    FirebaseFirestore.instance.useFirestoreEmulator(
      authEmulatorHost,
      firestoreEmulatorPort,
    );
    _connected = true;
  }
  return auth;
}

Future<User> signInAsGuest() async {
  final auth = await emulatedAuth();
  final credential = await auth.signInAnonymously();
  return credential.user!;
}

Future<void> signOutEverywhere() async {
  final auth = await emulatedAuth();
  await auth.signOut();
}

String uniqueEmail() =>
    'learner${DateTime.now().microsecondsSinceEpoch}@example.com';

Future<void> confirmEmailFromInbox(String email) async {
  final projectId = Firebase.app().options.projectId;
  final client = HttpClient();
  try {
    final codes = await _getJson(
      client,
      Uri.http(
        '$authEmulatorHost:$authEmulatorPort',
        '/emulator/v1/projects/$projectId/oobCodes',
      ),
    );
    final link = [
      for (final code in codes['oobCodes']! as List<Object?>)
        if (code
            case {
              'email': final String to,
              'requestType': 'VERIFY_EMAIL',
              'oobLink': final String link,
            }
            when to == email)
          link,
    ].last;
    final response = await (await client.getUrl(Uri.parse(link))).close();
    await response.drain<void>();
  } finally {
    client.close();
  }
}

Future<Map<String, Object?>> _getJson(HttpClient client, Uri uri) async {
  final response = await (await client.getUrl(uri)).close();
  final body = await response.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, Object?>;
}
