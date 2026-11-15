import 'package:meta/meta.dart';

@immutable
sealed class AppUser {
  const new(this.id);

  final String id;
}

final class GuestUser extends AppUser {
  const new(super.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GuestUser && other.id == id;

  @override
  int get hashCode => Object.hash(GuestUser, id);

  @override
  String toString() => 'GuestUser($id)';
}

final class MemberUser extends AppUser {
  const new(super.id, {required this.email, required this.emailVerified});

  final String email;
  final bool emailVerified;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberUser &&
          other.id == id &&
          other.email == email &&
          other.emailVerified == emailVerified;

  @override
  int get hashCode => Object.hash(MemberUser, id, email, emailVerified);

  @override
  String toString() =>
      'MemberUser($id, email: $email, emailVerified: $emailVerified)';
}
