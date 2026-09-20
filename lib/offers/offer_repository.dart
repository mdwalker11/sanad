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
    await client
        .from('service_orders')
        .update({'selected_offer_id': offerId, 'status': 'confirmed'})
        .eq('id', orderId);
    await client
        .from('service_offers')
        .update({'status': 'accepted'})
        .eq('id', offerId)
        .eq('order_id', orderId);
    await client
        .from('service_offers')
        .update({'status': 'rejected'})
        .eq('order_id', orderId)
        .neq('id', offerId)
        .eq('status', 'pending');
  }
}
