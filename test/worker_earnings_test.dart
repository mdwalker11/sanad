import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/workers/worker_earnings.dart';

void main() {
  group('WorkerSettlement.fromRow', () {
    test('يقرأ الحقول الرقمية القادمة كنص من PostgREST', () {
      final s = WorkerSettlement.fromRow(const {
        'order_id': 'o1',
        'gross_amount': '100.50',
        'commission_rate': '0.15',
        'commission_amount': '15.08',
        'worker_net_amount': '85.42',
        'status': 'pending',
        'due_at': '2026-01-10T10:00:00Z',
      });

      expect(s.grossAmount, 100.50);
      expect(s.workerNetAmount, 85.42);
      expect(s.commissionAmount, 15.08);
      expect(s.status, SettlementStatus.pending);
      expect(s.isPaid, isFalse);
    });

    test('يقرأ الأرقام القادمة كأعداد', () {
      final s = WorkerSettlement.fromRow(const {
        'order_id': 'o2',
        'gross_amount': 200,
        'worker_net_amount': 170,
        'status': 'paid',
        'paid_at': '2026-01-12T09:00:00Z',
      });

      expect(s.grossAmount, 200);
      expect(s.workerNetAmount, 170);
      expect(s.isPaid, isTrue);
      expect(s.paidAt, isNotNull);
    });

    test('لا ينهار على صف ناقص الحقول', () {
      final s = WorkerSettlement.fromRow(const {'order_id': 'o3'});

      expect(s.grossAmount, 0);
      expect(s.workerNetAmount, 0);
      expect(s.status, SettlementStatus.pending);
    });

    test('حالة غير معروفة تعامل كـ pending ولا ترمي', () {
      final s = WorkerSettlement.fromRow(const {
        'order_id': 'o4',
        'status': 'something_new_from_backend',
      });

      expect(s.status, SettlementStatus.pending);
    });
  });

  group('EarningsSummary', () {
    final rows = [
      WorkerSettlement.fromRow(const {
        'order_id': 'a',
        'gross_amount': 100,
        'worker_net_amount': 85,
        'commission_amount': 15,
        'status': 'paid',
        'paid_at': '2026-01-05T10:00:00Z',
      }),
      WorkerSettlement.fromRow(const {
        'order_id': 'b',
        'gross_amount': 200,
        'worker_net_amount': 170,
        'commission_amount': 30,
        'status': 'pending',
        'due_at': '2026-01-20T10:00:00Z',
      }),
      WorkerSettlement.fromRow(const {
        'order_id': 'c',
        'gross_amount': 50,
        'worker_net_amount': 42.5,
        'commission_amount': 7.5,
        'status': 'pending',
        'due_at': '2026-01-22T10:00:00Z',
      }),
    ];

    test('يفصل المحصَّل عن المستحق', () {
      final sum = EarningsSummary.from(rows);

      expect(sum.totalNet, closeTo(297.5, 0.001));
      expect(sum.paidNet, 85);
      expect(sum.pendingNet, closeTo(212.5, 0.001));
      expect(sum.jobCount, 3);
    });

    test('يحسب إجمالي العمولة المقتطعة', () {
      expect(EarningsSummary.from(rows).totalCommission, closeTo(52.5, 0.001));
    });

    test('متوسط الدخل لكل عملية', () {
      expect(EarningsSummary.from(rows).averageNet, closeTo(99.1667, 0.001));
    });

    test('قائمة فارغة تعطي أصفاراً بلا قسمة على صفر', () {
      final sum = EarningsSummary.from(const []);

      expect(sum.totalNet, 0);
      expect(sum.averageNet, 0);
      expect(sum.jobCount, 0);
      expect(sum.isEmpty, isTrue);
    });
  });

  group('تنسيق العملة الليبية', () {
    test('يعرض رقمين عشريين مع الرمز', () {
      expect(formatLyd(85.4), '85.40 د.ل');
      expect(formatLyd(1200), '1200.00 د.ل');
    });

    test('يعرض الصفر بشكل سليم', () {
      expect(formatLyd(0), '0.00 د.ل');
    });
  });
}
