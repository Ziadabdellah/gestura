import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestura/features/admin/domain/admin_access.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AdminAccess)
final class FirestoreAdminAccess implements AdminAccess {
  const new(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<bool> isAdmin(AppUser? user) async {
    if (user is! MemberUser || !user.emailVerified) return false;
    try {
      return (await _firestore.collection('admins').doc(user.email).get())
          .exists;
    } on FirebaseException {
      return false;
    }
  }
}
