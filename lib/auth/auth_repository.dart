import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_form.dart';

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
  }) {
    if (!form.isValid || fullName.trim().isEmpty || phone.trim().isEmpty) {
      throw ArgumentError('بيانات التسجيل ناقصة');
    }
    return client.auth.signUp(
      email: form.email,
      password: form.password,
      data: {'full_name': fullName.trim(), 'phone': phone.trim()},
    );
  }

  Future<void> signOut() => client.auth.signOut();
}
