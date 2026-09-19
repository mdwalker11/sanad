import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/core/order_flow.dart';

void main() {
  test('customer can create an order and worker can submit an offer', () {
    final repository = InMemoryOrderRepository();
    final customer = repository.createOrder(
      customerId: 'customer-1',
      serviceSlug: 'plumbing',
      description: 'تسريب تحت المغسلة',
      bookingType: BookingType.immediate,
    );

    final offer = repository.submitOffer(
      orderId: customer.id,
      workerId: 'worker-1',
      totalAmount: 120,
      estimatedArrivalMinutes: 30,
    );

    expect(customer.status, OrderStatus.awaitingOffers);
    expect(offer.totalAmount, 120);
    expect(repository.offersFor(customer.id), hasLength(1));
  });

  test('customer accepts an offer and order becomes confirmed', () {
    final repository = InMemoryOrderRepository();
    final order = repository.createOrder(
      customerId: 'customer-1',
      serviceSlug: 'electrical',
      description: 'تركيب مفتاح',
      bookingType: BookingType.scheduled,
    );
    final offer = repository.submitOffer(
      orderId: order.id,
      workerId: 'worker-1',
      totalAmount: 80,
      estimatedArrivalMinutes: 60,
    );

    final confirmed = repository.acceptOffer(order.id, offer.id);

    expect(confirmed.status, OrderStatus.confirmed);
    expect(confirmed.selectedWorkerId, 'worker-1');
    expect(repository.offersFor(order.id).single.status, OfferStatus.accepted);
  });

  test('worker cannot submit an offer for a completed order', () {
    final repository = InMemoryOrderRepository();
    final order = repository.createOrder(
      customerId: 'customer-1',
      serviceSlug: 'home-cleaning',
      description: 'تنظيف منزل',
      bookingType: BookingType.scheduled,
    );
    final offer = repository.submitOffer(
      orderId: order.id,
      workerId: 'worker-1',
      totalAmount: 200,
      estimatedArrivalMinutes: 90,
    );
    repository.acceptOffer(order.id, offer.id);
    repository.markCompleted(order.id);

    expect(
      () => repository.submitOffer(
        orderId: order.id,
        workerId: 'worker-1',
        totalAmount: 200,
        estimatedArrivalMinutes: 90,
      ),
      throwsA(isA<OrderFlowException>()),
    );
  });
}
