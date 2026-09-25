import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/operations/notifications_page.dart';

class _FakeSource implements NotificationsSource {
  _FakeSource({
    List<AppNotification>? items,
    this.error,
    this.markError,
    this.completer,
  }) : _items = List.of(items ?? const []);

  List<AppNotification> _items;
  final Object? error;
  final Object? markError;
  final Completer<List<AppNotification>>? completer;

  int fetchCount = 0;
  final markedIds = <String>[];

  @override
  Future<List<AppNotification>> fetch() {
    fetchCount++;
    if (completer != null) return completer!.future;
    if (error != null) return Future.error(error!);
    return Future.value(_items);
  }

  @override
  Future<void> markRead(String id) async {
    if (markError != null) throw markError!;
    markedIds.add(id);
    _items = _items
        .map(
          (n) => n.id == id
              ? AppNotification(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  isRead: true,
                  createdAt: n.createdAt,
                )
              : n,
        )
        .toList();
  }
}

AppNotification _n(String id, {bool read = false}) => AppNotification(
  id: id,
  title: 'عرض جديد $id',
  body: 'وصلك عرض على طلبك',
  isRead: read,
  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
);

void main() {
  group('relativeArabic', () {
    final now = DateTime(2026, 1, 10, 12);

    test('أقل من دقيقة', () {
      expect(
        relativeArabic(now.subtract(const Duration(seconds: 30)), now: now),
        'الآن',
      );
    });

    test('المثنى العربي للدقائق والساعات', () {
      expect(
        relativeArabic(now.subtract(const Duration(minutes: 2)), now: now),
        'قبل دقيقتين',
      );
      expect(
        relativeArabic(now.subtract(const Duration(hours: 2)), now: now),
        'قبل ساعتين',
      );
    });

    test('جمع القلة مقابل الكثرة', () {
      expect(
        relativeArabic(now.subtract(const Duration(minutes: 5)), now: now),
        'قبل 5 دقائق',
      );
      expect(
        relativeArabic(now.subtract(const Duration(minutes: 30)), now: now),
        'قبل 30 دقيقة',
      );
    });

    test('أمس ويومين', () {
      expect(
        relativeArabic(now.subtract(const Duration(days: 1)), now: now),
        'أمس',
      );
      expect(
        relativeArabic(now.subtract(const Duration(days: 2)), now: now),
        'قبل يومين',
      );
    });

    test('تاريخ غائب يعطي نصاً فارغاً لا استثناء', () {
      expect(relativeArabic(null), '');
    });
  });

  group('AppNotification.fromRow', () {
    test('read_at غير فارغ يعني مقروءاً', () {
      final n = AppNotification.fromRow(const {
        'id': '1',
        'title_ar': 'عنوان',
        'body_ar': 'نص',
        'read_at': '2026-01-01T00:00:00Z',
      });
      expect(n.isRead, isTrue);
    });

    test('صف ناقص لا ينهار ويعطي قيماً افتراضية', () {
      final n = AppNotification.fromRow(const {'id': '2'});
      expect(n.title, 'إشعار');
      expect(n.body, '');
      expect(n.isRead, isFalse);
    });
  });

  group('NotificationsPage', () {
    testWidgets('يعرض التحميل ثم المحتوى', (tester) async {
      final c = Completer<List<AppNotification>>();
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(source: _FakeSource(completer: c)),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('notifications_loading')), findsOneWidget);

      c.complete([_n('a')]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notifications_list')), findsOneWidget);
    });

    testWidgets('رسالة خطأ عربية ولا يتسرب Exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            source: _FakeSource(error: Exception('offline')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notifications_error')), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('زر إعادة المحاولة يعيد الجلب فعلياً', (tester) async {
      final source = _FakeSource(error: Exception('x'));
      await tester.pumpWidget(
        MaterialApp(home: NotificationsPage(source: source)),
      );
      await tester.pumpAndSettle();
      expect(source.fetchCount, 1);

      await tester.tap(find.byKey(const Key('notifications_retry')));
      await tester.pumpAndSettle();

      expect(source.fetchCount, 2);
    });

    testWidgets('العنوان يعرض عدد غير المقروء', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            source: _FakeSource(
              items: [_n('a'), _n('b'), _n('c', read: true)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الإشعارات (2)'), findsOneWidget);
    });

    testWidgets('لا عدّاد حين يكون الكل مقروءاً', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            source: _FakeSource(items: [_n('a', read: true)]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الإشعارات'), findsOneWidget);
      expect(find.byKey(const Key('notifications_mark_all')), findsNothing);
    });

    testWidgets('الضغط على إشعار غير مقروء يعلّمه مقروءاً', (tester) async {
      final source = _FakeSource(items: [_n('a')]);
      await tester.pumpWidget(
        MaterialApp(home: NotificationsPage(source: source)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notification_a')));
      await tester.pumpAndSettle();

      expect(source.markedIds, ['a']);
      expect(find.text('الإشعارات'), findsOneWidget);
    });

    testWidgets('تعليم الكل كمقروء يعالج كل غير المقروء', (tester) async {
      final source = _FakeSource(
        items: [_n('a'), _n('b'), _n('c', read: true)],
      );
      await tester.pumpWidget(
        MaterialApp(home: NotificationsPage(source: source)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notifications_mark_all')));
      await tester.pumpAndSettle();

      expect(source.markedIds, containsAll(<String>['a', 'b']));
      expect(source.markedIds.length, 2, reason: 'المقروء مسبقاً لا يُعاد');
      expect(find.byKey(const Key('notifications_mark_all')), findsNothing);
    });

    testWidgets('فشل التعليم يعرض تنبيهاً ولا ينهار', (tester) async {
      final source = _FakeSource(
        items: [_n('a')],
        markError: Exception('write failed'),
      );
      await tester.pumpWidget(
        MaterialApp(home: NotificationsPage(source: source)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notification_a')));
      await tester.pump();

      expect(find.text('تعذّر تحديث حالة الإشعار'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('حالة الفراغ مفهومة', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: NotificationsPage(source: _FakeSource())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notifications_empty')), findsOneWidget);
      expect(find.text('لا توجد إشعارات بعد'), findsOneWidget);
    });
  });
}
