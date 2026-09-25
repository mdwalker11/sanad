import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/order_request.dart';

void main() {
  test('combines selected date with a selected local time', () {
    final result = combineDateAndTime(
      DateTime(2026, 9, 21),
      const TimeOfDay(hour: 14, minute: 30),
    );

    expect(result, DateTime(2026, 9, 21, 14, 30));
  });

  test('rejects an end time that is not after the start time', () {
    expect(
      () => validateTimeWindow(
        DateTime(2026, 9, 21, 14),
        DateTime(2026, 9, 21, 13),
      ),
      throwsA(isA<OrderRequestException>()),
    );
  });
}
