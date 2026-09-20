import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/order_request.dart';

void main() {
  test('immediate order request uses the immediate booking type', () {
    final request = OrderRequest(
      customerId: 'customer-1',
      serviceId: 'service-1',
      description: 'صيانة',
      bookingType: BookingType.immediate,
    );

    expect(request.toInsertMap()['booking_type'], 'immediate');
  });
}
