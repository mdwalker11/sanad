import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/orders/create_order_page.dart';
import 'package:sanad/orders/order_repository.dart';
import 'package:sanad/orders/order_request.dart';

/// مستودع وهمي يحصي الاستدعاءات ويسمح بتأخير الرد،
/// حتى نتمكن من محاكاة شبكة بطيئة وضغط المستخدم مرتين.
class _FakeSink implements OrderSink {
  _FakeSink({this.addressDelay = Duration.zero, this.orderDelay = Duration.zero});

  final Duration addressDelay;
  final Duration orderDelay;

  int addressCalls = 0;
  int orderCalls = 0;
  OrderRequest? lastRequest;
  Object? throwOnOrder;

  @override
  Future<Map<String, dynamic>> createAddress({
    required String customerId,
    required String addressText,
  }) async {
    addressCalls++;
    if (addressDelay > Duration.zero) await Future<void>.delayed(addressDelay);
    return {'id': 'address-1', 'address_text': addressText};
  }

  @override
  Future<Map<String, dynamic>> createOrder(OrderRequest request) async {
    orderCalls++;
    lastRequest = request;
    if (orderDelay > Duration.zero) await Future<void>.delayed(orderDelay);
    if (throwOnOrder != null) throw throwOnOrder!;
    return {'id': 'order-1'};
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

CreateOrderPage _page(_FakeSink sink) => CreateOrderPage(
  serviceId: 'service-1',
  serviceName: 'تنظيف',
  customerId: 'customer-1',
  repository: sink,
);

void main() {
  testWidgets('الضغط مرتين بسرعة لا ينشئ طلبين', (tester) async {
    final sink = _FakeSink(orderDelay: const Duration(milliseconds: 300));
    await tester.pumpWidget(_wrap(_page(sink)));

    await tester.enterText(
      find.widgetWithText(TextField, 'وصف المطلوب'),
      'تنظيف شقة',
    );
    await tester.pump();

    final button = find.byKey(const Key('create_order_submit'));
    await tester.tap(button);
    await tester.pump();
    // ضغطة ثانية بينما الأولى ما زالت جارية.
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 400));

    expect(
      sink.orderCalls,
      1,
      reason: 'الضغط المزدوج يجب ألا ينشئ أكثر من طلب واحد',
    );
  });

  testWidgets('الضغط مرتين لا ينشئ عنواناً مكرراً', (tester) async {
    final sink = _FakeSink(addressDelay: const Duration(milliseconds: 300));
    await tester.pumpWidget(_wrap(_page(sink)));

    await tester.enterText(
      find.widgetWithText(TextField, 'وصف المطلوب'),
      'تنظيف شقة',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'العنوان أو المنطقة'),
      'طرابلس - حي الأندلس',
    );
    await tester.pump();

    final button = find.byKey(const Key('create_order_submit'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 500));

    expect(
      sink.addressCalls,
      1,
      reason: 'العنوان يجب ألا يُنشأ مرتين — وإلا امتلأ سجل العميل بتكرار',
    );
  });

  testWidgets('وصف فارغ يعرض رسالة عربية ولا يرسل شيئاً', (tester) async {
    final sink = _FakeSink();
    await tester.pumpWidget(_wrap(_page(sink)));

    await tester.tap(find.byKey(const Key('create_order_submit')));
    await tester.pumpAndSettle();

    expect(find.text('يرجى وصف الخدمة المطلوبة'), findsOneWidget);
    expect(sink.orderCalls, 0);
  });

  testWidgets('وصف فارغ لا ينشئ عنواناً في قاعدة البيانات', (tester) async {
    final sink = _FakeSink();
    await tester.pumpWidget(_wrap(_page(sink)));

    await tester.enterText(
      find.widgetWithText(TextField, 'العنوان أو المنطقة'),
      'طرابلس',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('create_order_submit')));
    await tester.pumpAndSettle();

    expect(
      sink.addressCalls,
      0,
      reason: 'طلب مرفوض للتحقق يجب ألا يترك عنواناً يتيماً في قاعدة البيانات',
    );
  });

  testWidgets('فشل الشبكة يعرض رسالة عربية ويعيد تفعيل الزر', (tester) async {
    final sink = _FakeSink()..throwOnOrder = Exception('network down');
    await tester.pumpWidget(_wrap(_page(sink)));

    await tester.enterText(
      find.widgetWithText(TextField, 'وصف المطلوب'),
      'تنظيف شقة',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('create_order_submit')));
    await tester.pumpAndSettle();

    expect(find.text('تعذر إنشاء الطلب، حاول مرة أخرى'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('create_order_submit')),
    );
    expect(
      button.onPressed,
      isNotNull,
      reason: 'بعد الفشل يجب أن يستطيع المستخدم إعادة المحاولة',
    );
  });

  testWidgets('طلب فوري ناجح يمرر النوع الصحيح', (tester) async {
    final sink = _FakeSink();
    await tester.pumpWidget(_wrap(_page(sink)));

    await tester.enterText(
      find.widgetWithText(TextField, 'وصف المطلوب'),
      'تنظيف شقة',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('create_order_submit')));
    await tester.pumpAndSettle();

    expect(sink.orderCalls, 1);
    expect(sink.lastRequest?.bookingType, BookingType.immediate);
    expect(sink.lastRequest?.description, 'تنظيف شقة');
  });

  testWidgets('موعد محدد بلا تاريخ يعرض رسالة ولا يرسل', (tester) async {
    final sink = _FakeSink();
    await tester.pumpWidget(_wrap(_page(sink)));

    await tester.enterText(
      find.widgetWithText(TextField, 'وصف المطلوب'),
      'صيانة مكيف',
    );
    await tester.pump();

    await tester.tap(find.byType(DropdownButtonFormField<BookingType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('موعد محدد').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_order_submit')));
    await tester.pumpAndSettle();

    expect(find.text('يرجى تحديد الموعد'), findsOneWidget);
    expect(sink.orderCalls, 0);
  });
}
