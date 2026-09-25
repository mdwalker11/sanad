import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/auth/auth_feedback.dart';

void main() {
  test('signup without session offers confirmation and resend guidance', () {
    expect(
      authSuccessMessage(isSignUp: true, hasSession: false),
      contains('تحقق'),
    );
    expect(
      shouldOfferVerificationResend(isSignUp: true, hasSession: false),
      isTrue,
    );
    expect(
      shouldOfferVerificationResend(isSignUp: true, hasSession: true),
      isFalse,
    );
  });
}
