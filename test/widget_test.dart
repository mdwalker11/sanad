import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/main.dart';

void main() {
  testWidgets('Sanad home shows core service categories', (tester) async {
    await tester.pumpWidget(const SanadApp());

    expect(find.text('سند'), findsOneWidget);
    expect(find.text('تنظيف المنزل'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('التكييف والتبريد'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('التكييف والتبريد'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('السباكة'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('السباكة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('الكهرباء'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('الكهرباء'), findsOneWidget);
  });

  testWidgets('customer can open a service request', (tester) async {
    await tester.pumpWidget(const SanadApp());
    await tester.scrollUntilVisible(
      find.text('السباكة'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('السباكة'));
    await tester.pumpAndSettle();

    expect(find.text('طلب السباكة'), findsOneWidget);
    expect(find.text('متابعة وإنشاء الطلب'), findsOneWidget);
  });
}
