import 'package:supabase_flutter/supabase_flutter.dart';

class OrderTransitionRepository {
  const OrderTransitionRepository(this.client);

  final SupabaseClient client;

  Future<void> workerUpdateStatus({
    required String orderId,
    required String status,
  }) async {
    await client.rpc(
      'worker_update_order_status',
      params: {'p_order_id': orderId, 'p_to_status': status},
    );
  }

  Future<void> customerComplete(String orderId) async {
    await client.rpc(
      'customer_complete_order',
      params: {'p_order_id': orderId},
    );
  }

  Future<void> customerCancel(String orderId) async {
    await client.rpc('customer_cancel_order', params: {'p_order_id': orderId});
  }

  static bool canCustomerCancel(String status) =>
      const {'new', 'under_review', 'awaiting_offers'}.contains(status);

  static bool canCustomerComplete(String status) =>
      status == 'awaiting_completion';

  static String? nextWorkerStatus(String status) => switch (status) {
    'confirmed' => 'on_the_way',
    'on_the_way' => 'in_progress',
    'in_progress' => 'awaiting_completion',
    _ => null,
  };

  static String actionLabel(String status) => switch (status) {
    'confirmed' => 'بدأت الطريق',
    'on_the_way' => 'بدأت الخدمة',
    'in_progress' => 'أتممت الخدمة',
    _ => 'تحديث الحالة',
  };
}
