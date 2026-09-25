import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/auth/auth_feedback.dart';

void main() {
  test('forgot password validation rejects an invalid email', () {
    expect(passwordResetValidation('invalid'), 'البريد الإلكتروني غير صالح');
  });

  test('forgot password validation accepts a trimmed email', () {
    expect(passwordResetValidation(' user@example.com '), isNull);
  });
}
