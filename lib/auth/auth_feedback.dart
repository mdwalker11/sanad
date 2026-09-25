String? authSuccessMessage({required bool isSignUp, required bool hasSession}) {
  if (!isSignUp) return null;
  if (hasSession) return 'تم إنشاء الحساب وتسجيل الدخول بنجاح.';
  return 'تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتفعيل الحساب.';
}

bool shouldOfferVerificationResend({
  required bool isSignUp,
  required bool hasSession,
}) => isSignUp && !hasSession;

String? passwordResetValidation(String email) {
  final value = email.trim();
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  return valid ? null : 'البريد الإلكتروني غير صالح';
}
