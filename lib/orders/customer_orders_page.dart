import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../complaints/complaint.dart';
import '../complaints/complaint_page.dart';
import '../offers/offer_list_page.dart';
import '../offers/offer_repository.dart';
import '../reviews/review_page.dart';
import 'customer_order_repository.dart';
import 'order_transition_repository.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({
    super.key,
    required this.repository,
    required this.customerId,
  });

  final CustomerOrderRepository repository;
  final String customerId;

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  late Future<List<CustomerOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = widget.repository.fetchForCustomer(widget.customerId);
  }

  Future<void> _refresh() async {
    setState(() {
      _orders = widget.repository.fetchForCustomer(widget.customerId);
    });
    await _orders;
  }

  Future<void> _runCustomerAction({
    required Future<void> Function() action,
    required String successMessage,
    required String errorMessage,
  }) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  Future<void> _openOrder(CustomerOrder order) async {
    if (order.status.value == 'awaiting_offers') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => OfferListPage(
            orderId: order.id,
            repository: WorkerOfferRepository(Supabase.instance.client),
          ),
        ),
      );
      if (mounted) await _refresh();
      return;
    }

    final transition = OrderTransitionRepository(Supabase.instance.client);
    if (OrderTransitionRepository.canCustomerComplete(order.status.value)) {
      await _runCustomerAction(
        action: () => transition.customerComplete(order.id),
        successMessage: 'تم تأكيد إنجاز الخدمة',
        errorMessage: 'تعذر تأكيد إنجاز الخدمة',
      );
      if (mounted && order.selectedWorkerId != null) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewPage(
              orderId: order.id,
              customerId: widget.customerId,
              workerId: order.selectedWorkerId!,
              repository: ReviewRepository(Supabase.instance.client),
            ),
          ),
        );
      }
      return;
    }

    if (!OrderTransitionRepository.canCustomerCancel(order.status.value)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الطلب؟'),
        content: const Text('سيتم إلغاء الطلب وإيقاف استقبال العروض.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runCustomerAction(
        action: () => transition.customerCancel(order.id),
        successMessage: 'تم إلغاء الطلب',
        errorMessage: 'تعذر إلغاء الطلب',
      );
    }
  }

  Future<void> _openComplaint(CustomerOrder order) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintPage(
          orderId: order.id,
          openedBy: widget.customerId,
          repository: ComplaintRepository(Supabase.instance.client),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلباتي')),
        body: FutureBuilder<List<CustomerOrder>>(
          future: _orders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('تعذر تحميل الطلبات'));
            }
            final orders = snapshot.data ?? const <CustomerOrder>[];
            if (orders.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('لا توجد طلبات بعد')),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final actionable =
                      order.status.value == 'awaiting_offers' ||
                      OrderTransitionRepository.canCustomerCancel(
                        order.status.value,
                      ) ||
                      OrderTransitionRepository.canCustomerComplete(
                        order.status.value,
                      );
                  return Card(
                    child: ListTile(
                      onTap: actionable ? () => _openOrder(order) : null,
                      onLongPress: () => _openComplaint(order),
                      leading: const CircleAvatar(
                        child: Icon(Icons.receipt_long_outlined),
                      ),
                      title: Text(order.serviceName ?? 'طلب خدمة'),
                      subtitle: Text(order.description),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(order.status.label),
                          if (order.status.value == 'awaiting_offers')
                            const Text(
                              'عرض العروض',
                              style: TextStyle(fontSize: 12),
                            ),
                          if (OrderTransitionRepository.canCustomerComplete(
                            order.status.value,
                          ))
                            const Text(
                              'تأكيد الإنجاز',
                              style: TextStyle(fontSize: 12),
                            ),
                          if (OrderTransitionRepository.canCustomerCancel(
                            order.status.value,
                          ))
                            const Text(
                              'إدارة الطلب',
                              style: TextStyle(fontSize: 12),
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

CustomerOrdersPage pageForCurrentCustomer() {
  final client = Supabase.instance.client;
  return CustomerOrdersPage(
    repository: CustomerOrderRepository(client),
    customerId: client.auth.currentUser!.id,
  );
}
