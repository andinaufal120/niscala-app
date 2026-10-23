enum PasswordStrength { none, weak, fair, strong, veryStrong }

const _minimumLength = 8;
const _minimumGuessWordLength = 4;

const _commonPasswords = {
  '12345678',
  'password',
  'password123',
  'qwerty123',
  'niscala123',
  'bismillah',
};

/// A hint for the user while typing. The server decides what is accepted.
///
/// Passwords that are short, common, repeated, a run of consecutive
/// characters, or built from the app name, the first word of [name] or the
/// local part of [email] are weak. Otherwise length decides.
PasswordStrength passwordStrength(
  String password, {
  String name = '',
  String email = '',
}) {
  if (password.isEmpty) return PasswordStrength.none;
  if (password.length < _minimumLength ||
      _isGuessable(password.toLowerCase(), name, email)) {
    return PasswordStrength.weak;
  }
  if (password.length < 12) return PasswordStrength.fair;
  if (password.length < 16) return PasswordStrength.strong;
  return PasswordStrength.veryStrong;
}

/// The Indonesian line that describes the strength of [password].
String passwordStrengthText(
  String password, {
  String name = '',
  String email = '',
}) {
  return switch (passwordStrength(password, name: name, email: email)) {
    PasswordStrength.none =>
      'Kekuatan kata sandi akan muncul saat Anda mengetik.',
    PasswordStrength.weak =>
      password.length < _minimumLength
          ? 'Kekuatan: Lemah · terlalu pendek'
          : 'Kekuatan: Lemah · mudah ditebak',
    PasswordStrength.fair =>
      'Kekuatan: Cukup · tambah panjangnya agar lebih aman',
    PasswordStrength.strong => 'Kekuatan: Kuat · sudah aman',
    PasswordStrength.veryStrong =>
      'Kekuatan: Sangat kuat · sangat sulit ditebak',
  };
}

bool _isGuessable(String lower, String name, String email) {
  if (_commonPasswords.contains(lower) || lower.contains('niscala')) {
    return true;
  }
  final firstName = name.trim().split(RegExp(r'\s+')).first.toLowerCase();
  final at = email.indexOf('@');
  final localPart = at < 0 ? '' : email.substring(0, at).toLowerCase();
  for (final word in [firstName, localPart]) {
    if (word.length >= _minimumGuessWordLength && lower.contains(word)) {
      return true;
    }
  }
  return lower.runes.toSet().length == 1 || _isRun(lower);
}

bool _isRun(String text) {
  final steps = {
    for (var i = 1; i < text.length; i++)
      text.codeUnitAt(i) - text.codeUnitAt(i - 1),
  };
  return steps.length == 1 && steps.first.abs() == 1;
}
