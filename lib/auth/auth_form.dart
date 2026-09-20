class AuthForm {
  AuthForm({required String email, required this.password})
    : email = email.trim();

  final String email;
  final String password;

  bool get isValid => _emailPattern.hasMatch(email) && password.length >= 6;

  String? get validationMessage {
    if (!_emailPattern.hasMatch(email)) return 'البريد الإلكتروني غير صالح';
    if (password.length < 6) return 'كلمة المرور قصيرة';
    return null;
  }

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
