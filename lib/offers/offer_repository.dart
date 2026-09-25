import 'package:supabase_flutter/supabase_flutter.dart';

import 'offer.dart';

class WorkerOfferRepository {
  const WorkerOfferRepository(this.client);

  final SupabaseClient client;

  Future<Map<String, dynamic>> submitOffer(ServiceOfferDraft offer) async {
    final row = await client
        .from('service_offers')
        .insert(offer.toInsertMap())
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> offersForOrder(String orderId) async {
    final rows = await client
        .from('service_offers')
        .select(
          'id, order_id, worker_id, status, total_amount, visit_amount, '
          'labor_amount, materials_amount, commission_rate, '
          'estimated_arrival_minutes, estimated_duration_minutes, includes, '
          'excludes, warranty_text, created_at',
        )
        .eq('order_id', orderId)
        .order('total_amount');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> acceptOffer({
    required String orderId,
    required String offerId,
  }) async {
    // Acceptance must be atomic and server-authorized. The RPC also verifies
    // ownership, offer state, order state, and records the order event.
    await client.rpc(
      'accept_service_offer',
      params: {'p_order_id': orderId, 'p_offer_id': offerId},
    );
  }
}
