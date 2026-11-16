import 'package:gestura/features/auth/domain/app_user.dart';

abstract interface class AdminAccess {
  Future<bool> isAdmin(AppUser? user);
}
