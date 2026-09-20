import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'customer_order_repository.dart';

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
    setState(
      () => _orders = widget.repository.fetchForCustomer(widget.customerId),
    );
    await _orders;
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
              return Center(child: Text('تعذر تحميل الطلبات'));
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
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.receipt_long_outlined),
                      ),
                      title: Text(order.serviceName ?? 'طلب خدمة'),
                      subtitle: Text(order.description),
                      trailing: Text(order.status.label),
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
