import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/support/support_page.dart';

void main() {
  testWidgets('يعرض قنوات التواصل الثلاث', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportPage()));

    expect(find.byKey(const Key('support_phone')), findsOneWidget);
    expect(find.byKey(const Key('support_whatsapp')), findsOneWidget);
    expect(find.byKey(const Key('support_email')), findsOneWidget);
  });

  testWidgets('الضغط على كل قناة يبلّغ فعلياً بالقناة الصحيحة', (tester) async {
    final tapped = <SupportChannel>[];
    await tester.pumpWidget(
      MaterialApp(home: SupportPage(onContact: tapped.add)),
    );

    await tester.tap(find.byKey(const Key('support_phone')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('support_whatsapp')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('support_email')));
    await tester.pump();

    expect(tapped, [
      SupportChannel.phone,
      SupportChannel.whatsapp,
      SupportChannel.email,
    ]);
  });

  testWidgets('الأسئلة المتكررة تتوسع عند الضغط وتكشف الإجابة', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportPage()));

    // الإجابة مخفية قبل الضغط.
    expect(find.textContaining('تُحصَّل الأرباح نقداً'), findsNothing);

    await tester.tap(find.byKey(const Key('faq_payout')));
    await tester.pumpAndSettle();

    expect(find.textContaining('تُحصَّل الأرباح نقداً'), findsOneWidget);
  });

  testWidgets('لا ينهار عند غياب onContact', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportPage()));

    await tester.tap(find.byKey(const Key('support_phone')));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('الشاشة بالاتجاه العربي RTL', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportPage()));

    final dir = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.byType(Scaffold),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(dir.textDirection, TextDirection.rtl);
  });
}
