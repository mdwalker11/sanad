import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cash commission at 20 percent leaves 80 percent worker net', () {
    const gross = 250.0;
    const rate = 20.0;
    final commission = gross * rate / 100;
    final net = gross - commission;
    expect(commission, 50.0);
    expect(net, 200.0);
  });

  test('order status notification payload contains the order and status', () {
    const payload = {'order_id': 'order-1', 'status': 'completed'};
    expect(payload['order_id'], 'order-1');
    expect(payload['status'], 'completed');
  });
}
