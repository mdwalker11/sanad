import 'package:supabase_flutter/supabase_flutter.dart';

class OperationsRepository {
  const OperationsRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> notifications(String userId) async {
    final rows = await client
        .from('notifications')
        .select('id, type, title_ar, body_ar, payload, read_at, created_at')
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  Future<List<Map<String, dynamic>>> workerSettlements(String workerId) async {
    final rows = await client
        .from('settlements')
        .select(
          'order_id, gross_amount, commission_rate, commission_amount, worker_net_amount, status, due_at, paid_at',
        )
        .eq('worker_id', workerId)
        .order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
