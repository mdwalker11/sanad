import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/order_request.dart';

void main() {
  test('time-window request requires both bounds', () {
    expect(
      () => OrderRequest(
        customerId: 'customer-1',
        serviceId: 'service-1',
        description: 'تنظيف',
        bookingType: BookingType.timeWindow,
        preferredStart: DateTime(2026, 9, 20, 10),
      ),
      throwsA(isA<OrderRequestException>()),
    );
  });
}
