import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sanad/support/support_page.dart';
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

  testWidgets('زر دعم سند يفتح شاشة الدعم فعلياً عند الضغط', (tester) async {
    // الشاشة الافتراضية 800x600 تقصّ العناصر السفلية من الـ ListView.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: ProviderHomePage(workerId: 'worker-1')),
    );
    await tester.pump();

    expect(find.byType(SupportPage), findsNothing);

    // المفتاح على الـ widget الخارجي، لذا نضغط الـ ListTile الواقع داخله.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('provider_support_action')),
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(SupportPage),
      findsOneWidget,
      reason: 'الزر كان ميتاً (onTap فارغ) قبل هذا الإصلاح',
    );
  });

  testWidgets('كل إجراءات الشاشة قابلة للضغط فعلياً', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: ProviderHomePage(workerId: 'worker-1')),
    );
    await tester.pump();

    // أي ListTile معطّل (onTap == null) يعني عنصراً يظهر ولا يستجيب.
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
    expect(tiles, isNotEmpty);
    for (final tile in tiles) {
      expect(
        tile.onTap,
        isNotNull,
        reason: 'عنصر يظهر للمستخدم لكنه لا يستجيب للضغط',
      );
    }
  });
}
