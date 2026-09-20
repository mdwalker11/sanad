import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/offers/offer.dart';

void main() {
  test('offer validates amount and creates insert payload', () {
    final offer = ServiceOfferDraft(
      orderId: 'order-1',
      workerId: 'worker-1',
      totalAmount: 250,
      visitAmount: 50,
      laborAmount: 150,
      materialsAmount: 50,
      estimatedArrivalMinutes: 30,
      estimatedDurationMinutes: 90,
      includes: 'فحص وإصلاح',
    );

    expect(offer.toInsertMap(), {
      'order_id': 'order-1',
      'worker_id': 'worker-1',
      'total_amount': 250.0,
      'visit_amount': 50.0,
      'labor_amount': 150.0,
      'materials_amount': 50.0,
      'commission_rate': 20.0,
      'estimated_arrival_minutes': 30,
      'estimated_duration_minutes': 90,
      'includes': 'فحص وإصلاح',
      'status': 'pending',
    });
  });

  test('offer rejects negative amounts', () {
    expect(
      () => ServiceOfferDraft(
        orderId: 'order-1',
        workerId: 'worker-1',
        totalAmount: -1,
      ),
      throwsA(isA<OfferException>()),
    );
  });
}
