import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/customer_order_repository.dart';

void main() {
  test('customer order parses service and Arabic status', () {
    final order = CustomerOrder.fromRow({
      'id': 'order-1',
      'order_number': 7,
      'description': 'إصلاح تسريب',
      'status': 'awaiting_offers',
      'created_at': '2026-09-20T10:00:00Z',
      'service_categories': {'name_ar': 'السباكة'},
    });

    expect(order.orderNumber, 7);
    expect(order.serviceName, 'السباكة');
    expect(order.status.label, 'بانتظار عروض العاملين');
  });
}
