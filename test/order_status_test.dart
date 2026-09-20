import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/order_status.dart';

void main() {
  test('order status has Arabic labels for customer tracking', () {
    expect(OrderStatusLabel.fromValue('new').label, 'جديد');
    expect(
      OrderStatusLabel.fromValue('awaiting_offers').label,
      'بانتظار عروض العاملين',
    );
    expect(OrderStatusLabel.fromValue('confirmed').label, 'تم تأكيد العامل');
    expect(OrderStatusLabel.fromValue('completed').label, 'اكتملت الخدمة');
  });

  test('unknown order status is safe for the user interface', () {
    expect(OrderStatusLabel.fromValue('future_status').label, 'قيد المتابعة');
  });
}
