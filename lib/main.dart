import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/supabase_bootstrap.dart';
import 'catalog/service_catalog.dart';
import 'catalog/service_catalog_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await SupabaseBootstrap.initialize(config);
  runApp(SanadApp(supabaseConfigured: config.isValid));
}

class SanadApp extends StatelessWidget {
  const SanadApp({super.key, this.supabaseConfigured = false});

  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سند',
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF315D47),
          surface: const Color(0xFFF7F6F2),
        ),
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF7F6F2),
      ),
      home: SanadHomePage(supabaseConfigured: supabaseConfigured),
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
    final catalog = await ServiceCatalogRepository(Supabase.instance.client)
        .fetchActive();
    return catalog.items;
  }

  static const _fallbackServices = <ServiceCatalogItem>[
    ServiceCatalogItem(
      slug: 'home-cleaning',
      name: 'تنظيف المنزل',
      description: 'عاملات موثوقات',
      sortOrder: 1,
    ),
    ServiceCatalogItem(
      slug: 'ac-cooling',
      name: 'التكييف والتبريد',
      description: 'فنيون متاحون',
      sortOrder: 2,
    ),
    ServiceCatalogItem(
      slug: 'plumbing',
      name: 'السباكة',
      description: 'حلول سريعة',
      sortOrder: 3,
    ),
    ServiceCatalogItem(
      slug: 'electrical',
      name: 'الكهرباء',
      description: 'محترفون موثقون',
      sortOrder: 4,
    ),
    ServiceCatalogItem(
      slug: 'furniture-assembly',
      name: 'تركيب الأثاث',
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

  void _showBooking(String service) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'طلب $service',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            const TextField(
              decoration: InputDecoration(
                labelText: 'صف ما تحتاجه',
                hintText: 'أضف التفاصيل أو أرفق صورة لاحقًا',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on_outlined),
              title: Text('موقع الخدمة'),
              subtitle: Text('اختر المنطقة والعنوان'),
              trailing: Icon(Icons.chevron_left),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule_outlined),
              title: Text('الموعد'),
              subtitle: Text('موعد محدد أو طلب فوري'),
              trailing: Icon(Icons.chevron_left),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('تم تجهيز طلبك للمطابقة')),
                );
              },
              child: const Text('متابعة وإنشاء الطلب'),
            ),
          ],
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
          backgroundColor: Colors.transparent,
          title: const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF315D47),
                child: Text('س', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 10),
              Text('سند', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: CircleAvatar(child: Text('م')),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            children: [
              Text(
                'العناية بالمنزل، بطريقة أذكى',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'قل لنا ما يحتاجه منزلك،\nونتولى الباقي.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'اطلب فنيًا موثوقًا إلى منزلك، بسعر واضح وموعد يناسبك.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.7),
              ),
              const SizedBox(height: 22),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'اكتب ما تحتاجه وسنقترح عليك الخدمة المناسبة.',
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ماذا يحتاج منزلك اليوم؟',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('عرض الكل')),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<ServiceCatalogItem>>(
                future: _servicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final services = snapshot.data ?? _fallbackServices;
                  return Column(
                    children: services
                        .map(
                          (service) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              elevation: 0,
                              child: ListTile(
                                onTap: () => _showBooking(service.name),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE2EADF),
                                  child: Icon(
                                    _iconFor(service.slug),
                                    color: const Color(0xFF315D47),
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
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF315D47),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تحتاج مساعدة الآن؟',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'نبحث عن أقرب محترف متاح.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _showBooking('مساعدة فورية'),
                        child: const Text('اطلب الآن'),
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
          onDestinationSelected: (index) => setState(() => _tab = index),
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
