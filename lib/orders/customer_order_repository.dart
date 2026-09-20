import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_status.dart';

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.description,
    required this.status,
    required this.createdAt,
    this.serviceName,
  });

  final String id;
  final int? orderNumber;
  final String description;
  final OrderStatusLabel status;
  final DateTime createdAt;
  final String? serviceName;

  factory CustomerOrder.fromRow(Map<String, dynamic> row) {
    final service = row['service_categories'];
    final serviceMap = service is Map
        ? Map<String, dynamic>.from(service)
        : null;
    return CustomerOrder(
      id: row['id'] as String,
      orderNumber: (row['order_number'] as num?)?.toInt(),
      description: row['description'] as String? ?? '',
      status: OrderStatusLabel.fromValue(row['status'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      serviceName: serviceMap?['name_ar'] as String?,
    );
  }
}

class CustomerOrderRepository {
  const CustomerOrderRepository(this.client);

  final SupabaseClient client;

  Future<List<CustomerOrder>> fetchForCustomer(String customerId) async {
    final rows = await client
        .from('service_orders')
        .select(
          'id, order_number, description, booking_type, status, created_at, '
          'service_categories(name_ar)',
        )
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => CustomerOrder.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }
}
