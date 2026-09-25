import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/workers/worker_earnings.dart';
import 'package:sanad/workers/worker_earnings_page.dart';

/// مصدر وهمي يتحكم في النتيجة بدقة — نجاح، فشل، فارغ، أو معلّق.
class _FakeSource implements WorkerEarningsSource {
  _FakeSource({this.rows = const [], this.error, this.completer});

  final List<WorkerSettlement> rows;
  final Object? error;
  final Completer<List<WorkerSettlement>>? completer;

  int callCount = 0;

  @override
  Future<List<WorkerSettlement>> fetchSettlements() {
    callCount++;
    if (completer != null) return completer!.future;
    if (error != null) return Future.error(error!);
    return Future.value(rows);
  }
}

WorkerSettlement _s({
  required double net,
  required double gross,
  required double commission,
  String status = 'pending',
}) {
  return WorkerSettlement.fromRow({
    'order_id': 'o-$net',
    'gross_amount': gross,
    'commission_amount': commission,
    'worker_net_amount': net,
    'status': status,
  });
}

void main() {
  testWidgets('يعرض مؤشر تحميل قبل وصول البيانات', (tester) async {
    final completer = Completer<List<WorkerSettlement>>();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerEarningsPage(source: _FakeSource(completer: completer)),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('earnings_loading')), findsOneWidget);

    completer.complete(const []);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('earnings_loading')), findsNothing);
  });

  testWidgets('يعرض رسالة فارغة مفهومة عند غياب الأرباح', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: WorkerEarningsPage(source: _FakeSource())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('earnings_empty')), findsOneWidget);
    expect(find.textContaining('بعد إتمام أول خدمة'), findsOneWidget);
  });

  testWidgets('يعرض رسالة خطأ عربية ولا ينهار عند فشل الشبكة', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerEarningsPage(
          source: _FakeSource(error: Exception('network down')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('earnings_error')), findsOneWidget);
    expect(find.textContaining('تعذّر تحميل سجل الأرباح'), findsOneWidget);
    // لا يتسرب نص الاستثناء الخام للمستخدم.
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('زر إعادة المحاولة يستدعي المصدر فعلياً عند الضغط', (
    tester,
  ) async {
    final source = _FakeSource(error: Exception('boom'));
    await tester.pumpWidget(
      MaterialApp(home: WorkerEarningsPage(source: source)),
    );
    await tester.pumpAndSettle();

    expect(source.callCount, 1);

    await tester.tap(find.byKey(const Key('earnings_retry_button')));
    await tester.pumpAndSettle();

    expect(source.callCount, 2, reason: 'الضغط يجب أن يعيد الطلب فعلاً');
  });

  testWidgets('زر التحديث في الشريط يعيد الجلب', (tester) async {
    final source = _FakeSource(rows: [_s(net: 85, gross: 100, commission: 15)]);
    await tester.pumpWidget(
      MaterialApp(home: WorkerEarningsPage(source: source)),
    );
    await tester.pumpAndSettle();

    expect(source.callCount, 1);

    await tester.tap(find.byKey(const Key('earnings_refresh_button')));
    await tester.pumpAndSettle();

    expect(source.callCount, 2);
  });

  testWidgets('يحسب ويعرض الإجماليات الصحيحة', (tester) async {
    final source = _FakeSource(
      rows: [
        _s(net: 85, gross: 100, commission: 15, status: 'paid'),
        _s(net: 170, gross: 200, commission: 30),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: WorkerEarningsPage(source: source)),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('earnings_total_net'))).data,
      '255.00 د.ل',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('earnings_paid'))).data,
      '85.00 د.ل',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('earnings_pending'))).data,
      '170.00 د.ل',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('earnings_job_count'))).data,
      '2',
    );
  });

  testWidgets('التسويات الملغاة لا تُحتسب في الأرباح', (tester) async {
    final source = _FakeSource(
      rows: [
        _s(net: 100, gross: 120, commission: 20, status: 'paid'),
        _s(net: 999, gross: 999, commission: 0, status: 'cancelled'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: WorkerEarningsPage(source: source)),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('earnings_total_net'))).data,
      '100.00 د.ل',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('earnings_job_count'))).data,
      '1',
    );
  });

  testWidgets('الشاشة بالاتجاه العربي RTL', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: WorkerEarningsPage(source: _FakeSource())),
    );
    await tester.pumpAndSettle();

    final dir = tester.widget<Directionality>(
      find.ancestor(
        of: find.byType(Scaffold),
        matching: find.byType(Directionality),
      ).first,
    );
    expect(dir.textDirection, TextDirection.rtl);
  });
}
