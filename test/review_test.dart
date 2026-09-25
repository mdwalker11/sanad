import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/reviews/review.dart';

void main() {
  test('review creates a valid insert payload', () {
    final review = ReviewDraft(
      orderId: 'order-1',
      customerId: 'customer-1',
      workerId: 'worker-1',
      rating: 5,
      comment: 'خدمة ممتازة',
    );

    expect(review.toInsertMap(), {
      'order_id': 'order-1',
      'customer_id': 'customer-1',
      'worker_id': 'worker-1',
      'rating': 5,
      'comment': 'خدمة ممتازة',
    });
  });

  test('review rejects rating outside range', () {
    expect(
      () => ReviewDraft(
        orderId: 'order-1',
        customerId: 'customer-1',
        workerId: 'worker-1',
        rating: 0,
      ),
      throwsA(isA<ReviewException>()),
    );
  });
}
