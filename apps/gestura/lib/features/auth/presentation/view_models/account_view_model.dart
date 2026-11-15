import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/account_state.dart';
import 'package:gestura/features/learner/learner_cloud.dart';
import 'package:gestura/features/learner/learner_data.dart';
import 'package:gestura_core/gestura_core.dart';

class AccountViewModel extends Cubit<AccountState> {
  new(this._auth, this._local, this._cloud)
    : super(stateOf(_auth.currentUser)) {
    _subscription = _auth.watchUser().listen((user) => emit(stateOf(user)));
  }

  final AuthRepository _auth;
  final LearnerData _local;
  final LearnerCloud _cloud;
  late final StreamSubscription<AppUser?> _subscription;

  static AccountState stateOf(AppUser? user) => switch (user) {
    null => const AccountSignedOut(),
    GuestUser() => const AccountGuest(),
    MemberUser(:final email, :final emailVerified) => AccountMember(
      email: email,
      emailVerified: emailVerified,
    ),
  };

  Future<Result<void>> signOut() => _auth.signOut();

  Future<Result<void>> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return const Ok(null);
    emit(const AccountDeleting());
    final steps = <Future<Result<void>> Function()>[
      if (password != null) () => _auth.reauthenticate(password: password),
      () => _cloud.deleteAll(user.id),
      _auth.deleteAccount,
    ];
    for (final step in steps) {
      final result = await step();
      if (result case Err()) {
        if (!isClosed) emit(stateOf(_auth.currentUser));
        return result;
      }
    }
    return await _local.clear();
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
