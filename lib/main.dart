import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_page.dart';
import 'config/app_config.dart';
import 'config/supabase_bootstrap.dart';
import 'catalog/service_catalog.dart';
import 'catalog/service_catalog_repository.dart';
import 'orders/order_repository.dart';
import 'operations/notifications_page.dart';
import 'orders/create_order_page.dart';
import 'orders/customer_orders_page.dart';
import 'workers/worker_orders_page.dart';
import 'workers/worker_profile_page.dart';
import 'workers/worker_repository.dart';

const _brandGreen = Color(0xFF164C3B);
const _brandMint = Color(0xFFDFF3EA);
const _ink = Color(0xFF15211C);
const _canvas = Color(0xFFF7F9F6);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await SupabaseBootstrap.initialize(config);
  runApp(SanadApp(supabaseConfigured: config.isValid, previewMode: false));
}

class SanadApp extends StatelessWidget {
  const SanadApp({
    super.key,
    this.supabaseConfigured = false,
    this.previewMode = true,
  });
  final bool supabaseConfigured;
  // Preview mode is used only by local widget tests and design previews.
  // Production entrypoints must disable it so missing runtime config is visible.
  final bool previewMode;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _brandGreen,
      brightness: Brightness.light,
      surface: _canvas,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سند',
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _canvas,
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: _canvas,
          foregroundColor: _ink,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(22)),
            side: BorderSide(color: Color(0xFFE4ECE6)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color(0xFFDCE7E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color(0xFFDCE7E0)),
          ),
        ),
      ),
      home: supabaseConfigured
          ? AuthGate(
              homeBuilder: (_) => const SanadHomePage(supabaseConfigured: true),
            )
          : previewMode
          ? const SanadHomePage()
          : const ConfigurationRequiredPage(),
    );
  }
}

class ConfigurationRequiredPage extends StatelessWidget {
  const ConfigurationRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'تعذر تشغيل سند الآن. إعدادات الاتصال غير مكتملة.\n'
              'أعد تشغيل النسخة بإعدادات Supabase الصحيحة.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class SanadHomePage extends StatefulWidget {
  const SanadHomePage({super.key, this.supabaseConfigured = false});
  final bool supabaseConfigured;

  @override
  State<SanadHomePage> createState() => _SanadHomePageState();
}

class _SanadHomePageState extends State<SanadHomePage> {
  late Future<List<ServiceCatalogItem>> _servicesFuture;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _loadServices();
  }

  Future<List<ServiceCatalogItem>> _loadServices() async {
    if (!widget.supabaseConfigured) return _fallbackServices;
    try {
      return (await ServiceCatalogRepository(
        Supabase.instance.client,
      ).fetchActive()).items;
    } catch (_) {
      return _fallbackServices;
    }
  }

  static const _fallbackServices = <ServiceCatalogItem>[
    ServiceCatalogItem(
      id: 'home-cleaning',
      slug: 'home-cleaning',
      name: 'تنظيف المنزل',
      description: 'عاملات موثوقات',
      sortOrder: 1,
    ),
    ServiceCatalogItem(
      id: 'ac-cooling',
      slug: 'ac-cooling',
      name: 'التكييف والتبريد',
      description: 'فنيون متاحون',
      sortOrder: 2,
    ),
    ServiceCatalogItem(
      id: 'plumbing',
      slug: 'plumbing',
      name: 'السباكة',
      description: 'حلول سريعة',
      sortOrder: 3,
    ),
    ServiceCatalogItem(
      id: 'electrical',
      slug: 'electrical',
      name: 'الكهرباء',
      description: 'محترفون موثقون',
      sortOrder: 4,
    ),
    ServiceCatalogItem(
      id: 'furniture-assembly',
      slug: 'furniture-assembly',
      name: 'فك وتركيب الأثاث',
      description: 'عروض واضحة',
      sortOrder: 5,
    ),
  ];

  IconData _iconFor(String slug) => switch (slug) {
    'home-cleaning' => Icons.cleaning_services_outlined,
    'ac-cooling' => Icons.ac_unit_outlined,
    'plumbing' => Icons.water_drop_outlined,
    'electrical' => Icons.bolt_outlined,
    _ => Icons.weekend_outlined,
  };

  void _openCreateOrder(ServiceCatalogItem service) {
    if (!widget.supabaseConfigured) {
      _showBooking(service.name);
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderPage(
          serviceId: service.id,
          serviceName: service.name,
          customerId: userId,
          repository: OrderRepository(Supabase.instance.client),
        ),
      ),
    );
  }

  void _showBooking(String service) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'طلب $service',
              style: Theme.of(
                sheetContext,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'صف ما تحتاجه',
                hintText: 'أضف التفاصيل هنا',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سجّل الدخول لإنشاء طلب حقيقي')),
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('متابعة'),
            ),
          ],
        ),
      ),
    );
  }

  void _openOrders() {
    if (!widget.supabaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول لمتابعة طلباتك')),
      );
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => pageForCurrentCustomer()),
    );
  }

  void _openWorkerMode() {
    if (!widget.supabaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول للوصول إلى وضع العامل')),
      );
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول للوصول إلى وضع العامل')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.engineering_outlined),
                title: Text('وضع العامل'),
                subtitle: Text('أكمل ملفك ثم استقبل طلبات مناسبة لمهاراتك'),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('ملف العامل'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerProfilePage(
                        repository: WorkerRepository(Supabase.instance.client),
                        userId: userId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('الطلبات المناسبة'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerOrdersPage(
                        workerId: userId,
                        repository: WorkerOrdersRepository(
                          Supabase.instance.client,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotifications() {
    if (!widget.supabaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول لعرض الإشعارات')),
      );
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => NotificationsPage(userId: userId)),
    );
  }

  void _showAccount() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: _brandMint,
                child: Icon(Icons.person, color: _brandGreen, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                widget.supabaseConfigured
                    ? (Supabase.instance.client.auth.currentUser?.email ??
                          'حساب سند')
                    : 'زائر سند',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              if (widget.supabaseConfigured)
                ListTile(
                  leading: const Icon(Icons.engineering_outlined),
                  title: const Text('وضع العامل'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openWorkerMode();
                  },
                ),

              if (widget.supabaseConfigured)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('تسجيل الخروج'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Supabase.instance.client.auth.signOut();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: _brandGreen,
                child: Text(
                  'س',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'سند',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _openNotifications,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                onPressed: _showAccount,
                icon: const CircleAvatar(
                  backgroundColor: _brandMint,
                  child: Icon(Icons.person_outline, color: _brandGreen),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _brandGreen,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'العناية بالمنزل، بطريقة أذكى',
                      style: TextStyle(
                        color: Color(0xFFBFE8D2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'قل لنا ما يحتاجه منزلك،\nونتولى الباقي.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'فنيون موثوقون، عروض واضحة، وخدمة تصل إلى بابك.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonalIcon(
                      onPressed: () => _showBooking('مساعدة فورية'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('اطلب خدمة الآن'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ماذا يحتاج منزلك اليوم؟',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!widget.supabaseConfigured)
                    TextButton(
                      onPressed: _openWorkerMode,
                      child: const Text('وضع العامل'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<ServiceCatalogItem>>(
                future: _servicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final services = snapshot.data ?? _fallbackServices;
                  return Column(
                    children: services.map((service) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            onTap: () => _openCreateOrder(service),
                            leading: CircleAvatar(
                              backgroundColor: _brandMint,
                              child: Icon(
                                _iconFor(service.slug),
                                color: _brandGreen,
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
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFFFFF1D6),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF9A6418),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'نختار لك محترفين موثوقين في طرابلس.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        key: const Key('trust_info_button'),
                        tooltip: 'كيف نختار المحترفين؟',
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (_) => const _TrustSheet(),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) {
            setState(() => _tab = index);
            if (index == 1) _openOrders();
            if (index == 2) _showAccount();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'طلباتي',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

/// لوحة تشرح معايير اختيار المحترفين — تبني ثقة العميل بدل سهم لا يفعل شيئاً.
class _TrustSheet extends StatelessWidget {
  const _TrustSheet();

  static const _criteria = <(IconData, String, String)>[
    (
      Icons.badge_outlined,
      'تحقق من الهوية',
      'كل مقدم خدمة يقدّم إثبات هوية رسمياً قبل استقبال أي طلب.',
    ),
    (
      Icons.handyman_outlined,
      'تقييم المهارة',
      'نراجع خبرة كل محترف في تخصصه قبل اعتماده على المنصة.',
    ),
    (
      Icons.star_outline,
      'تقييمات العملاء',
      'تقييمك بعد كل خدمة يؤثر مباشرة في استمرار المحترف معنا.',
    ),
    (
      Icons.support_agent_outlined,
      'متابعة التشغيل',
      'فريق سند يتابع الشكاوى ويتدخل عند أي خلل في الخدمة.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'كيف نختار المحترفين؟',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._criteria.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(c.$1, color: _brandGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.$3,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const Key('trust_sheet_close'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('فهمت'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
