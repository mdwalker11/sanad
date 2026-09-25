import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/order_transition_repository.dart';

void main() {
  test('worker status progression is explicit and finite', () {
    expect(
      OrderTransitionRepository.nextWorkerStatus('confirmed'),
      'on_the_way',
    );
    expect(
      OrderTransitionRepository.nextWorkerStatus('on_the_way'),
      'in_progress',
    );
    expect(
      OrderTransitionRepository.nextWorkerStatus('in_progress'),
      'awaiting_completion',
    );
    expect(OrderTransitionRepository.nextWorkerStatus('completed'), isNull);
  });

  test('customer actions are allowed only in safe states', () {
    expect(
      OrderTransitionRepository.canCustomerCancel('awaiting_offers'),
      isTrue,
    );
    expect(OrderTransitionRepository.canCustomerCancel('confirmed'), isFalse);
    expect(
      OrderTransitionRepository.canCustomerComplete('awaiting_completion'),
      isTrue,
    );
    expect(OrderTransitionRepository.canCustomerComplete('completed'), isFalse);
  });

  test('worker status actions have Arabic labels', () {
    expect(OrderTransitionRepository.actionLabel('confirmed'), 'بدأت الطريق');
    expect(OrderTransitionRepository.actionLabel('on_the_way'), 'بدأت الخدمة');
    expect(
      OrderTransitionRepository.actionLabel('in_progress'),
      'أتممت الخدمة',
    );
  });
}
