import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/auth/auth_page.dart';

void main() {
  testWidgets('auth page shows branded entry and password visibility control', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignInPage()));

    expect(find.text('كيف ستستخدم سند؟'), findsOneWidget);
    expect(find.text('أبحث عن خدمة منزلية'), findsOneWidget);
    expect(find.text('أقدّم خدمات منزلية'), findsOneWidget);

    await tester.tap(find.text('أبحث عن خدمة منزلية'));
    await tester.pump();
    expect(find.text('إنشاء حساب عميل'), findsOneWidget);
    expect(find.byTooltip('إظهار كلمة المرور'), findsOneWidget);

    await tester.tap(find.byTooltip('إظهار كلمة المرور'));
    await tester.pump();
    expect(find.byTooltip('إخفاء كلمة المرور'), findsOneWidget);
  });
}
