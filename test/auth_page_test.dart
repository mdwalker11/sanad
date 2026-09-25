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

  testWidgets('اختيار "أقدّم خدمات منزلية" ينقل إلى نموذج تسجيل العامل', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignInPage()));

    await tester.tap(find.byKey(const Key('role_choice_worker')));
    await tester.pumpAndSettle();

    // لو بقيت الشاشة على اختيار الدور فالضغط لم يُحدث أثراً.
    expect(find.text('كيف ستستخدم سند؟'), findsNothing);
    expect(find.text('إنشاء حساب عميل'), findsNothing);
    expect(find.text('إنشاء حساب مقدم خدمة'), findsOneWidget);
  });

  testWidgets('كل دور ينقل إلى نموذجه الصحيح لا نموذج الآخر', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInPage()));

    await tester.tap(find.byKey(const Key('role_choice_customer')));
    await tester.pumpAndSettle();
    expect(find.text('إنشاء حساب عميل'), findsOneWidget);

    // الرجوع ثم اختيار العامل يجب ألا يُبقي نموذج العميل.
    await tester.tap(find.text('تغيير'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('role_choice_worker')));
    await tester.pumpAndSettle();

    expect(
      find.text('إنشاء حساب عميل'),
      findsNothing,
      reason: 'اختيار العامل يجب ألا يعرض نموذج العميل',
    );
    expect(find.text('إنشاء حساب مقدم خدمة'), findsOneWidget);
  });

  testWidgets('حقول التسجيل تقبل الإدخال فعلياً', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInPage()));

    await tester.tap(find.byKey(const Key('role_choice_worker')));
    await tester.pumpAndSettle();

    final emailField = find.widgetWithText(TextField, 'البريد الإلكتروني');
    expect(emailField, findsOneWidget);

    await tester.enterText(emailField, 'worker@example.ly');
    await tester.pump();

    expect(find.text('worker@example.ly'), findsOneWidget);
  });
}
