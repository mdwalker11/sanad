import 'package:supabase_flutter/supabase_flutter.dart';

import 'role.dart';

class RoleRepository {
  const RoleRepository(this.client);
  final SupabaseClient client;

  Future<AppRole> currentRole() async {
    final rows = await client
        .from('user_roles')
        .select('role')
        .eq('user_id', client.auth.currentUser!.id)
        .eq('is_active', true);
    return resolvePrimaryRole(rows.map((row) => row['role'] as String));
  }
}
