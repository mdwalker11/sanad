import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'worker_earnings.dart';

/// مصدر بيانات الأرباح الذي تعتمد عليه الشاشة.
///
/// الشاشة لا تعرف Supabase — هذا يسمح باختبار كل الحالات
/// (تحميل، نجاح، فشل، فارغ) دون شبكة.
abstract class WorkerEarningsSource {
  Future<List<WorkerSettlement>> fetchSettlements();
}

/// التنفيذ الفعلي المدعوم بـ Supabase.
class SupabaseWorkerEarningsSource implements WorkerEarningsSource {
  const SupabaseWorkerEarningsSource(this.client, this.workerId);

  final SupabaseClient client;
  final String workerId;

  @override
  Future<List<WorkerSettlement>> fetchSettlements() async {
    final rows = await client
        .from('settlements')
        .select(
          'order_id, gross_amount, commission_rate, commission_amount, '
          'worker_net_amount, status, due_at, paid_at',
        )
        .eq('worker_id', workerId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => WorkerSettlement.fromRow(Map<String, dynamic>.from(r)))
        .toList();
  }
}

/// شاشة "سجل الأعمال والأرباح" للعامل.
class WorkerEarningsPage extends StatefulWidget {
  const WorkerEarningsPage({super.key, required this.source});

  final WorkerEarningsSource source;

  @override
  State<WorkerEarningsPage> createState() => _WorkerEarningsPageState();
}

class _WorkerEarningsPageState extends State<WorkerEarningsPage> {
  bool _loading = true;
  String? _error;
  List<WorkerSettlement> _settlements = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.source.fetchSettlements();
      if (!mounted) return;
      setState(() {
        _settlements = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // رسالة عربية مفهومة تقول ما العمل، لا Exception خام.
      setState(() {
        _error = 'تعذّر تحميل سجل الأرباح. تحقق من الاتصال ثم أعد المحاولة.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الأعمال والأرباح'),
          actions: [
            IconButton(
              key: const Key('earnings_refresh_button'),
              tooltip: 'تحديث',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        key: Key('earnings_loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        key: const Key('earnings_error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  key: const Key('earnings_retry_button'),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final summary = EarningsSummary.from(_settlements);

    if (summary.isEmpty) {
      return const Center(
        key: Key('earnings_empty'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'لا توجد أرباح بعد.\nستظهر هنا تلقائياً بعد إتمام أول خدمة.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: const Key('earnings_list'),
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(summary: summary),
          const SizedBox(height: 20),
          const Text(
            'تفاصيل العمليات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ..._settlements.map((s) => _SettlementTile(settlement: s)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('earnings_summary_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إجمالي صافي الأرباح'),
            const SizedBox(height: 4),
            Text(
              formatLyd(summary.totalNet),
              key: const Key('earnings_total_net'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'محصَّلة',
                    value: formatLyd(summary.paidNet),
                    valueKey: const Key('earnings_paid'),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'مستحقة',
                    value: formatLyd(summary.pendingNet),
                    valueKey: const Key('earnings_pending'),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'عدد العمليات',
                    value: '${summary.jobCount}',
                    valueKey: const Key('earnings_job_count'),
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'متوسط العملية',
                    value: formatLyd(summary.averageNet),
                    valueKey: const Key('earnings_average'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.valueKey,
    this.color,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          key: valueKey,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _SettlementTile extends StatelessWidget {
  const _SettlementTile({required this.settlement});

  final WorkerSettlement settlement;

  @override
  Widget build(BuildContext context) {
    final paid = settlement.isPaid;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: paid
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.15),
          child: Icon(
            paid ? Icons.check_circle_outline : Icons.schedule,
            color: paid ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          formatLyd(settlement.workerNetAmount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'من ${formatLyd(settlement.grossAmount)} — '
          'عمولة ${formatLyd(settlement.commissionAmount)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Chip(
          label: Text(
            settlement.status.labelAr,
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: paid
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.orange.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
