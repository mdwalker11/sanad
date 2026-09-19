import 'package:flutter/material.dart';

void main() => runApp(const SanadApp());

class SanadApp extends StatelessWidget {
  const SanadApp({super.key});

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
      home: const SanadHomePage(),
    );
  }
}

class SanadHomePage extends StatefulWidget {
  const SanadHomePage({super.key});

  @override
  State<SanadHomePage> createState() => _SanadHomePageState();
}

class _SanadHomePageState extends State<SanadHomePage> {
  int _tab = 0;
  final _services = const [
    ('تنظيف المنزل', 'عاملات موثوقات', Icons.cleaning_services_outlined),
    ('التكييف والتبريد', 'فنيون متاحون', Icons.ac_unit_outlined),
    ('السباكة', 'حلول سريعة', Icons.water_drop_outlined),
    ('الكهرباء', 'محترفون موثقون', Icons.bolt_outlined),
    ('تركيب الأثاث', 'عروض واضحة', Icons.weekend_outlined),
  ];

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
              ..._services.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    elevation: 0,
                    child: ListTile(
                      onTap: () => _showBooking(service.$1),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE2EADF),
                        child: Icon(service.$3, color: const Color(0xFF315D47)),
                      ),
                      title: Text(
                        service.$1,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(service.$2),
                      trailing: const Icon(Icons.chevron_left),
                    ),
                  ),
                ),
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
