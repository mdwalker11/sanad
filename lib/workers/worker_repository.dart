import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/role.dart';
import 'worker_profile.dart';

/// Contract the worker profile screen depends on.
///
/// The screen must not depend on [SupabaseClient] directly, otherwise its
/// save path cannot be exercised in a widget test without a live backend.
abstract class WorkerProfileSink {
  Future<void> saveProfile(WorkerProfileDraft profile);
}

class WorkerRepository implements WorkerProfileSink {
  const WorkerRepository(this.client);

  final SupabaseClient client;

  @override
  Future<void> saveProfile(WorkerProfileDraft profile) async {
    final roles = await client
        .from('user_roles')
        .select('role')
        .eq('user_id', profile.userId)
        .eq('is_active', true);
    final role = resolvePrimaryRole(roles.map((row) => row['role'] as String));
    if (role != AppRole.worker) {
      throw const WorkerProfileException('حساب مقدم الخدمة غير مفعّل');
    }
    await client
        .from('worker_profiles')
        .upsert(profile.toInsertMap())
        .select()
        .single();
  }
}

class WorkerOrdersRepository {
  const WorkerOrdersRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> availableOrders(String workerId) async {
    final rows = await client
        .from('service_orders')
        .select(
          'id, order_number, description, booking_type, status, created_at, '
          'service_categories(name_ar)',
        )
        .eq('status', 'awaiting_offers')
        .order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
