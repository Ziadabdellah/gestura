import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/admin/domain/admin_access.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';

class AdminAccessViewModel extends Cubit<bool> {
  new(AuthRepository auth, this._access) : super(false) {
    _subscription = auth.watchUser().listen(_check);
    unawaited(_check(auth.currentUser));
  }

  final AdminAccess _access;
  late final StreamSubscription<AppUser?> _subscription;

  Future<void> _check(AppUser? user) async {
    final admin = await _access.isAdmin(user);
    if (!isClosed) emit(admin);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
