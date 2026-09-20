import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/main.dart';

void main() {
  testWidgets('Sanad home shows core service categories', (tester) async {
    await tester.pumpWidget(const SanadApp());
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('السباكة'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final plumbing = find.text('السباكة');
    await tester.ensureVisible(plumbing);
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(of: plumbing, matching: find.byType(ListTile)),
    );
    await tester.pumpAndSettle();

    expect(find.text('طلب السباكة'), findsOneWidget);
    expect(find.text('متابعة وإنشاء الطلب'), findsOneWidget);
  });
}
