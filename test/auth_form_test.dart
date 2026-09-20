import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/auth/auth_form.dart';

void main() {
  test('valid sign-in form trims email and preserves password', () {
    final form = AuthForm(email: '  user@example.com ', password: 'secret123');

    expect(form.email, 'user@example.com');
    expect(form.isValid, isTrue);
  });

  test('invalid sign-in form rejects malformed email and short password', () {
    final form = AuthForm(email: 'not-an-email', password: '123');

    expect(form.isValid, isFalse);
    expect(form.validationMessage, isNotNull);
  });
}
