import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_request.dart';

class OrderRepository {
  const OrderRepository(this.client);

  final SupabaseClient client;

  Future<Map<String, dynamic>> createOrder(OrderRequest request) async {
    final row = await client
        .from('service_orders')
        .insert(request.toInsertMap())
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> customerOrders(String customerId) async {
    final rows = await client
        .from('service_orders')
        .select(
          'id, order_number, description, booking_type, status, created_at, '
          'service_categories(name_ar)',
        )
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
