import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../offers/offer.dart';
import '../offers/offer_repository.dart';

class WorkerOrdersPage extends StatefulWidget {
  const WorkerOrdersPage({
    super.key,
    required this.workerId,
    required this.repository,
  });

  final String workerId;
  final WorkerOrdersRepository repository;

  @override
  State<WorkerOrdersPage> createState() => _WorkerOrdersPageState();
}

class _WorkerOrdersPageState extends State<WorkerOrdersPage> {
  late Future<List<Map<String, dynamic>>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = widget.repository.availableOrders(widget.workerId);
  }

  Future<void> _refresh() async {
    setState(
      () => _orders = widget.repository.availableOrders(widget.workerId),
    );
    await _orders;
  }

  Future<void> _offer(Map<String, dynamic> order) async {
    final result = await showDialog<ServiceOfferDraft>(
      context: context,
      builder: (_) => OfferDialog(
        orderId: order['id'] as String,
        workerId: widget.workerId,
      ),
    );
    if (result == null) return;
    try {
      await WorkerOfferRepository(Supabase.instance.client).submitOffer(result);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إرسال العرض')));
      await _refresh();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر إرسال العرض')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلبات مناسبة لك')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _orders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return const Center(child: Text('تعذر تحميل الطلبات'));
            final orders = snapshot.data ?? const <Map<String, dynamic>>[];
            if (orders.isEmpty)
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('لا توجد طلبات مناسبة حاليًا')),
                  ],
                ),
              );
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final order = orders[index];
                  final service = order['service_categories'] is Map
                      ? order['service_categories']['name_ar']
                      : 'طلب خدمة';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            service as String,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(order['description'] as String? ?? ''),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => _offer(order),
                            child: const Text('إرسال عرض سعر'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class OfferDialog extends StatefulWidget {
  const OfferDialog({super.key, required this.orderId, required this.workerId});
  final String orderId;
  final String workerId;

  @override
  State<OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<OfferDialog> {
  final _total = TextEditingController();
  final _arrival = TextEditingController(text: '60');
  final _includes = TextEditingController();

  @override
  void dispose() {
    _total.dispose();
    _arrival.dispose();
    _includes.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      final offer = ServiceOfferDraft(
        orderId: widget.orderId,
        workerId: widget.workerId,
        totalAmount: double.parse(_total.text),
        estimatedArrivalMinutes: int.tryParse(_arrival.text),
        includes: _includes.text.trim().isEmpty ? null : _includes.text.trim(),
      );
      Navigator.pop(context, offer);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('عرض السعر'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _total,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'الإجمالي بالدينار'),
        ),
        TextField(
          controller: _arrival,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'الوصول بالدقائق'),
        ),
        TextField(
          controller: _includes,
          decoration: const InputDecoration(labelText: 'ما يشمله العرض'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(onPressed: _submit, child: const Text('إرسال')),
    ],
  );
}
