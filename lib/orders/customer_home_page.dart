import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../account/account_page.dart';
import '../catalog/service_catalog.dart';
import '../catalog/service_catalog_repository.dart';
import '../orders/create_order_page.dart';
import '../orders/customer_orders_page.dart';
import '../orders/order_repository.dart';

const _customerGreen = Color(0xFF164C3B);
const _customerMint = Color(0xFFDFF3EA);

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key, required this.userId});
  final String userId;

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  late Future<List<ServiceCatalogItem>> _services;

  @override
  void initState() {
    super.initState();
    _services = _loadServices();
  }

  Future<List<ServiceCatalogItem>> _loadServices() async {
    final rows = await ServiceCatalogRepository(
      Supabase.instance.client,
    ).fetchActive();
    return rows.items;
  }

  IconData _icon(String slug) => switch (slug) {
    'home-cleaning' => Icons.cleaning_services_outlined,
    'ac-cooling' => Icons.ac_unit_outlined,
    'plumbing' => Icons.water_drop_outlined,
    'electrical' => Icons.bolt_outlined,
    _ => Icons.weekend_outlined,
  };

  void _openService(ServiceCatalogItem service) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderPage(
          serviceId: service.id,
          serviceName: service.name,
          customerId: widget.userId,
          repository: OrderRepository(Supabase.instance.client),
        ),
      ),
    );
  }

  void _openOrders() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => pageForCurrentCustomer()),
    );
  }

  void _openAccount() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountPage(
          email: user.email ?? 'حساب سند',
          roleLabel: 'عميل',
          onSignOut: () => Supabase.instance.client.auth.signOut(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('سند'),
        actions: [
          IconButton(
            tooltip: 'طلباتي',
            onPressed: _openOrders,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'إدارة الحساب',
            onPressed: _openAccount,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _services = _loadServices()),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _customerGreen,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خدمة موثوقة تصل إلى بابك',
                    style: TextStyle(
                      color: Color(0xFFBFE8D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'ماذا يحتاج منزلك اليوم؟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اختر الخدمة، صف احتياجك، واستقبل عروضًا واضحة من محترفين موثوقين.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الخدمات المتاحة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                TextButton.icon(
                  onPressed: _openOrders,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('طلباتي'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<ServiceCatalogItem>>(
              future: _services,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.wifi_off_outlined),
                      title: const Text('تعذر تحميل الخدمات'),
                      subtitle: const Text('اسحب الشاشة لإعادة المحاولة.'),
                      onTap: () => setState(() => _services = _loadServices()),
                    ),
                  );
                }
                final services = snapshot.data ?? const <ServiceCatalogItem>[];
                if (services.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.home_repair_service_outlined),
                      title: Text('لا توجد خدمات متاحة الآن'),
                      subtitle: Text('سيظهر الكتالوج هنا عند توفر الخدمات.'),
                    ),
                  );
                }
                return Column(
                  children: services
                      .map(
                        (service) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: _customerMint,
                              child: Icon(
                                _icon(service.slug),
                                color: _customerGreen,
                              ),
                            ),
                            title: Text(
                              service.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(service.description),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => _openService(service),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
