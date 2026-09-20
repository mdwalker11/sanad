import 'package:supabase_flutter/supabase_flutter.dart';

import 'worker_profile.dart';

class WorkerRepository {
  const WorkerRepository(this.client);

  final SupabaseClient client;

  Future<void> saveProfile(WorkerProfileDraft profile) async {
    await client.from('worker_profiles').upsert(profile.toInsertMap());
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
