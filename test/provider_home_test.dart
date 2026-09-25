import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sanad/workers/provider_home_page.dart';

void main() {
  testWidgets('provider home exposes provider-only actions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProviderHomePage(workerId: 'worker-1')),
    );
    await tester.pump();

    expect(find.text('مساحة مقدم الخدمة'), findsOneWidget);
    expect(find.text('الطلبات الجديدة'), findsOneWidget);
    expect(find.text('ملفي المهني'), findsOneWidget);
    expect(find.text('طلب خدمة الآن'), findsNothing);
  });
}
