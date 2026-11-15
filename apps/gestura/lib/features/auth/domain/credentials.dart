enum EmailProblem { missing, invalid }

enum PasswordProblem { missing, tooShort }

abstract final class Credentials {
  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String normalizeEmail(String email) => email.trim();

  static EmailProblem? checkEmail(String email) =>
      switch (normalizeEmail(email)) {
        '' => EmailProblem.missing,
        final value when !_email.hasMatch(value) => EmailProblem.invalid,
        _ => null,
      };

  static PasswordProblem? checkPassword(String password, {bool isNew = false}) {
    if (password.isEmpty) return PasswordProblem.missing;
    if (isNew && password.length < minPasswordLength) {
      return PasswordProblem.tooShort;
    }
    return null;
  }
}
