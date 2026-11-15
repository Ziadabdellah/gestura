import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/credentials.dart';

void main() {
  group('AppUser', () {
    test('compares guests by id', () {
      final id = String.fromCharCodes('uid'.codeUnits);

      expect(GuestUser(id), const GuestUser('uid'));
      expect(GuestUser(id).hashCode, const GuestUser('uid').hashCode);
      expect(const GuestUser('uid'), isNot(const GuestUser('other')));
      expect(const GuestUser('uid').toString(), 'GuestUser(uid)');
    });

    test('compares members by id, email and confirmation', () {
      const member = MemberUser('uid', email: 'a@b.co', emailVerified: true);
      final email = String.fromCharCodes('a@b.co'.codeUnits);

      expect(MemberUser('uid', email: email, emailVerified: true), member);
      expect(
        MemberUser('uid', email: email, emailVerified: true).hashCode,
        member.hashCode,
      );
      expect(
        member,
        isNot(const MemberUser('uid', email: 'a@b.co', emailVerified: false)),
      );
      expect(member, isNot(const GuestUser('uid')));
      expect(
        member.toString(),
        'MemberUser(uid, email: a@b.co, emailVerified: true)',
      );
    });
  });

  group('Credentials', () {
    test('accepts a usual email address, ignoring spaces around it', () {
      expect(Credentials.checkEmail('learner@example.com'), isNull);
      expect(Credentials.checkEmail('  learner@example.co.uk '), isNull);
      expect(Credentials.normalizeEmail('  a@b.co '), 'a@b.co');
    });

    test('names what is wrong with an email address', () {
      expect(Credentials.checkEmail(''), EmailProblem.missing);
      expect(Credentials.checkEmail('   '), EmailProblem.missing);
      for (final email in ['learner', 'learner@', '@example.com', 'a b@c.de']) {
        expect(Credentials.checkEmail(email), EmailProblem.invalid);
      }
    });

    test('asks new passwords for eight characters', () {
      expect(Credentials.minPasswordLength, 8);
      expect(Credentials.checkPassword(''), PasswordProblem.missing);
      expect(Credentials.checkPassword('short'), isNull);
      expect(
        Credentials.checkPassword('short', isNew: true),
        PasswordProblem.tooShort,
      );
      expect(Credentials.checkPassword('long enough', isNew: true), isNull);
    });
  });
}
