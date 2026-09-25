import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/complaints/complaint.dart';

void main() {
  test('complaint creates a valid insert payload', () {
    final complaint = ComplaintDraft(
      orderId: 'order-1',
      openedBy: 'customer-1',
      category: 'جودة الخدمة',
      description: 'أحتاج إلى مراجعة الخدمة',
    );

    expect(complaint.toInsertMap(), {
      'order_id': 'order-1',
      'opened_by': 'customer-1',
      'category': 'جودة الخدمة',
      'description': 'أحتاج إلى مراجعة الخدمة',
    });
  });

  test('complaint rejects blank details', () {
    expect(
      () => ComplaintDraft(
        orderId: 'order-1',
        openedBy: 'customer-1',
        category: 'أخرى',
        description: ' ',
      ),
      throwsA(isA<ComplaintException>()),
    );
  });
}
