import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/order_request.dart';

void main() {
  test('order request builds a valid Supabase insert payload', () {
    final request = OrderRequest(
      customerId: 'customer-1',
      serviceId: 'service-1',
      addressId: 'address-1',
      description: 'تسريب في المطبخ',
      bookingType: BookingType.immediate,
    );

    expect(request.toInsertMap(), {
      'customer_id': 'customer-1',
      'service_id': 'service-1',
      'address_id': 'address-1',
      'description': 'تسريب في المطبخ',
      'booking_type': 'immediate',
      'status': 'new',
    });
  });

  test('order request rejects blank description', () {
    expect(
      () => OrderRequest(
        customerId: 'customer-1',
        serviceId: 'service-1',
        description: ' ',
        bookingType: BookingType.scheduled,
      ),
      throwsA(isA<OrderRequestException>()),
    );
  });
}
