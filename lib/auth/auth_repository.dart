import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_form.dart';
import 'role.dart';

class AuthRepository {
  const AuthRepository(this.client);

  final SupabaseClient client;

  Future<AuthResponse> signIn(AuthForm form) {
    if (!form.isValid) {
      throw ArgumentError(form.validationMessage);
    }
    return client.auth.signInWithPassword(
      email: form.email,
      password: form.password,
    );
  }

  Future<AuthResponse> signUp({
    required AuthForm form,
    required String fullName,
    required String phone,
    String? emailRedirectTo,
    AppRole role = AppRole.customer,
  }) {
    if (!form.isValid || fullName.trim().isEmpty || phone.trim().isEmpty) {
      throw ArgumentError('بيانات التسجيل ناقصة');
    }
    return client.auth.signUp(
      email: form.email,
      password: form.password,
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'requested_role': role.name,
      },
      emailRedirectTo: emailRedirectTo,
    );
  }

  Future<void> resetPassword(String email, {String? redirectTo}) async {
    final value = email.trim();
    if (value.isEmpty || !value.contains('@')) {
      throw ArgumentError('البريد الإلكتروني غير صالح');
    }
    await client.auth.resetPasswordForEmail(value, redirectTo: redirectTo);
  }

  Future<void> signOut() => client.auth.signOut();
}
