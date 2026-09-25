import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/customer_home_page.dart';

void main() {
  testWidgets('customer home exposes customer-only booking language', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CustomerHomePage(userId: 'customer-1')),
    );
    await tester.pump();

    expect(find.text('ماذا يحتاج منزلك اليوم؟'), findsOneWidget);
    expect(find.text('طلباتي'), findsOneWidget);
  });
}
