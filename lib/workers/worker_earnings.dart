/// نموذج أرباح العامل.
///
/// خالٍ تماماً من أي اعتماد على Supabase أو Flutter حتى يمكن اختباره
/// بالكامل دون شبكة. الشاشة تستهلك هذه الأنواع فقط.
library;

/// حالة التسوية المالية كما تردها قاعدة البيانات.
enum SettlementStatus {
  /// مستحقة ولم تُدفع بعد.
  pending,

  /// حُصِّلت من العميل وسُلِّمت للعامل.
  paid,

  /// أُلغيت (طلب ملغى أو نزاع).
  cancelled;

  static SettlementStatus fromValue(String? raw) {
    switch (raw) {
      case 'paid':
      case 'settled':
        return SettlementStatus.paid;
      case 'cancelled':
      case 'canceled':
        return SettlementStatus.cancelled;
      default:
        // أي حالة جديدة من الخادم تُعامل كمستحقة بدل أن ترمي استثناء
        // ويظهر للعامل شاشة بيضاء.
        return SettlementStatus.pending;
    }
  }

  String get labelAr => switch (this) {
    SettlementStatus.pending => 'مستحقة',
    SettlementStatus.paid => 'محصَّلة',
    SettlementStatus.cancelled => 'ملغاة',
  };
}

/// يحوّل قيمة رقمية قد تصل كنص (PostgREST يرسل numeric كنص) إلى double.
double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// تسوية مالية واحدة مرتبطة بطلب مكتمل.
class WorkerSettlement {
  const WorkerSettlement({
    required this.orderId,
    required this.grossAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.workerNetAmount,
    required this.status,
    this.dueAt,
    this.paidAt,
  });

  /// معرّف الطلب الذي نتجت عنه هذه التسوية.
  final String orderId;

  /// المبلغ الذي دفعه العميل قبل خصم العمولة.
  final double grossAmount;

  /// نسبة عمولة المنصة (0.15 = 15%).
  final double commissionRate;

  /// قيمة العمولة المقتطعة.
  final double commissionAmount;

  /// صافي ما يستحقه العامل.
  final double workerNetAmount;

  final SettlementStatus status;
  final DateTime? dueAt;
  final DateTime? paidAt;

  bool get isPaid => status == SettlementStatus.paid;

  factory WorkerSettlement.fromRow(Map<String, dynamic> row) {
    return WorkerSettlement(
      orderId: row['order_id']?.toString() ?? '',
      grossAmount: _toDouble(row['gross_amount']),
      commissionRate: _toDouble(row['commission_rate']),
      commissionAmount: _toDouble(row['commission_amount']),
      workerNetAmount: _toDouble(row['worker_net_amount']),
      status: SettlementStatus.fromValue(row['status']?.toString()),
      dueAt: _toDate(row['due_at']),
      paidAt: _toDate(row['paid_at']),
    );
  }
}

/// ملخّص محسوب من قائمة تسويات — ما يظهر في أعلى شاشة الأرباح.
class EarningsSummary {
  const EarningsSummary({
    required this.totalNet,
    required this.paidNet,
    required this.pendingNet,
    required this.totalCommission,
    required this.jobCount,
  });

  /// إجمالي صافي الأرباح (محصَّلة + مستحقة).
  final double totalNet;

  /// ما وصل العامل فعلاً.
  final double paidNet;

  /// ما لم يصله بعد.
  final double pendingNet;

  /// ما اقتطعته المنصة إجمالاً.
  final double totalCommission;

  /// عدد العمليات المحتسبة.
  final int jobCount;

  bool get isEmpty => jobCount == 0;

  /// متوسط الدخل لكل عملية؛ صفر عند غياب العمليات (لا قسمة على صفر).
  double get averageNet => jobCount == 0 ? 0 : totalNet / jobCount;

  factory EarningsSummary.from(List<WorkerSettlement> settlements) {
    // الملغاة لا تُحتسب ضمن الأرباح إطلاقاً.
    final counted = settlements
        .where((s) => s.status != SettlementStatus.cancelled)
        .toList();

    var total = 0.0;
    var paid = 0.0;
    var commission = 0.0;

    for (final s in counted) {
      total += s.workerNetAmount;
      commission += s.commissionAmount;
      if (s.isPaid) paid += s.workerNetAmount;
    }

    return EarningsSummary(
      totalNet: total,
      paidNet: paid,
      pendingNet: total - paid,
      totalCommission: commission,
      jobCount: counted.length,
    );
  }
}

/// تنسيق مبلغ بالدينار الليبي.
String formatLyd(double amount) => '${amount.toStringAsFixed(2)} د.ل';
