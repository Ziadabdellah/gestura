import 'package:flutter/foundation.dart';

class AppGate extends ChangeNotifier {
  new({required this._onboarded, required this._signedIn});

  bool _onboarded;
  bool _signedIn;

  bool get onboarded => _onboarded;

  bool get signedIn => _signedIn;

  set onboarded(bool value) {
    if (value == _onboarded) return;
    _onboarded = value;
    notifyListeners();
  }

  set signedIn(bool value) {
    if (value == _signedIn) return;
    _signedIn = value;
    notifyListeners();
  }
}
