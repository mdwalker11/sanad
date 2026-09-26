// اختبارات تفاعل نافذة تقديم العرض — مسار المال المباشر للعامل.
//
// الأعطال التي تثبتها هذه الاختبارات (RED قبل الإصلاح):
//  1. حقل إجمالي فارغ → `double.parse('')` يرمي FormatException
//     فتظهر للعامل رسالة إنجليزية: "FormatException: Invalid double".
//  2. نص غير رقمي ("مئة") → نفس الانهيار بنفس الرسالة الإنجليزية.
//  3. لا حماية من الضغط المزدوج على "إرسال".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/offers/offer.dart';
import 'package:sanad/workers/worker_orders_page.dart';

Future<ServiceOfferDraft?> _openDialog(WidgetTester tester) async {
  ServiceOfferDraft? result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open'),
                onPressed: () async {
                  result = await showDialog<ServiceOfferDraft>(
                    context: context,
                    builder: (_) => const OfferDialog(
                      orderId: 'order-1',
                      workerId: 'worker-1',
                    ),
                  );
                },
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('حقل الإجمالي الفارغ يعرض رسالة عربية لا FormatException', (
    tester,
  ) async {
    await _openDialog(tester);

    await tester.tap(find.byKey(const Key('offer_submit')));
    await tester.pumpAndSettle();

    // لا يجوز أن تتسرب رسالة Dart الإنجليزية إلى المستخدم.
    expect(find.textContaining('FormatException'), findsNothing);
    expect(find.textContaining('Invalid double'), findsNothing);
    expect(find.text('يرجى إدخال قيمة العرض'), findsOneWidget);
  });

  testWidgets('نص غير رقمي يعرض رسالة عربية مفهومة', (tester) async {
    await _openDialog(tester);

    await tester.enterText(find.byKey(const Key('offer_total')), 'مئة');
    await tester.tap(find.byKey(const Key('offer_submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('FormatException'), findsNothing);
    expect(find.text('يرجى إدخال رقم صحيح للإجمالي'), findsOneWidget);
  });

  testWidgets('مبلغ سالب يُرفض برسالة عربية', (tester) async {
    await _openDialog(tester);

    await tester.enterText(find.byKey(const Key('offer_total')), '-50');
    await tester.tap(find.byKey(const Key('offer_submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('OfferException'), findsNothing);
    expect(find.text('لا يمكن أن تكون مبالغ العرض سالبة'), findsOneWidget);
  });

  testWidgets('عرض صالح يُغلق النافذة ويعيد المسودة', (tester) async {
    ServiceOfferDraft? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open'),
                  onPressed: () async {
                    captured = await showDialog<ServiceOfferDraft>(
                      context: context,
                      builder: (_) => const OfferDialog(
                        orderId: 'order-1',
                        workerId: 'worker-1',
                      ),
                    );
                  },
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('offer_total')), '250.5');
    await tester.enterText(find.byKey(const Key('offer_arrival')), '30');
    await tester.tap(find.byKey(const Key('offer_submit')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.totalAmount, 250.5);
    expect(captured!.estimatedArrivalMinutes, 30);
    expect(captured!.orderId, 'order-1');
  });

  testWidgets('المبالغ التفصيلية إن ذُكرت يجب أن تساوي الإجمالي', (
    tester,
  ) async {
    // القيد في قاعدة البيانات (015) يرفض عرضاً مجموع تفاصيله يخالف إجماليه.
    // يجب أن يُمنع ذلك في الواجهة قبل أن يصل إلى الخادم ويفشل بخطأ غامض.
    expect(
      () => ServiceOfferDraft(
        orderId: 'o',
        workerId: 'w',
        totalAmount: 100,
        visitAmount: 50,
        laborAmount: 50,
        materialsAmount: 50, // المجموع 150 ≠ 100
      ),
      throwsA(
        isA<OfferException>().having(
          (e) => e.message,
          'message',
          contains('مجموع'),
        ),
      ),
    );
  });

  testWidgets('تفاصيل متسقة مع الإجمالي تُقبل', (tester) async {
    final offer = ServiceOfferDraft(
      orderId: 'o',
      workerId: 'w',
      totalAmount: 150,
      visitAmount: 50,
      laborAmount: 60,
      materialsAmount: 40,
    );
    expect(offer.totalAmount, 150);
  });

  testWidgets('العمولة لا تُرسل من العميل إطلاقاً', (tester) async {
    // العمولة تُفرض من الخادم (guard_service_offer_insert + trigger 015).
    // إرسالها من التطبيق يوهم بأنها قابلة للتفاوض.
    final offer = ServiceOfferDraft(
      orderId: 'o',
      workerId: 'w',
      totalAmount: 100,
    );
    expect(offer.toInsertMap().containsKey('commission_rate'), isFalse);
  });
}
