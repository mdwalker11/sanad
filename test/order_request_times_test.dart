import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/order_request.dart';

void main() {
  test('scheduled request carries UTC time bounds', () {
    final request = OrderRequest(
      customerId: 'customer-1',
      serviceId: 'service-1',
      description: 'إصلاح',
      bookingType: BookingType.scheduled,
      preferredStart: DateTime(2026, 9, 20, 10),
      preferredEnd: DateTime(2026, 9, 20, 11),
    );

    final payload = request.toInsertMap();

    expect(payload['preferred_start'], contains('2026-09-20T'));
    expect(payload['preferred_end'], contains('2026-09-20T'));
  });
}
