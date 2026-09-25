import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../account/account_page.dart';

import 'worker_orders_page.dart';
import 'worker_profile_page.dart';
import 'worker_repository.dart';

class ProviderHomePage extends StatelessWidget {
  const ProviderHomePage({super.key, required this.workerId, this.client});
  final String workerId;
  final SupabaseClient? client;

  @override
  Widget build(BuildContext context) {
    final user = client?.auth.currentUser;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مساحة مقدم الخدمة'),
          actions: [
            IconButton(
              tooltip: 'إدارة الحساب',
              onPressed: user == null
                  ? null
                  : () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountPage(
                          email: user.email ?? 'حساب سند',
                          roleLabel: 'مقدم خدمة',
                          onSignOut: () => (client ?? Supabase.instance.client)
                              .auth
                              .signOut(),
                        ),
                      ),
                    ),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'أهلًا بك في سند',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text('تابع فرصك وأنجز أعمالك بثقة ووضوح.'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _Metric(label: 'طلبات جديدة', value: '—'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Metric(label: 'أعمال مكتملة', value: '—'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ProviderAction(
              icon: Icons.assignment_outlined,
              title: 'الطلبات الجديدة',
              subtitle: 'استعرض الطلبات المناسبة لمهاراتك وقدّم عرضًا.',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerOrdersPage(
                    workerId: workerId,
                    repository: WorkerOrdersRepository(
                      client ?? Supabase.instance.client,
                    ),
                  ),
                ),
              ),
            ),
            _ProviderAction(
              icon: Icons.badge_outlined,
              title: 'ملفي المهني',
              subtitle: 'حدّث خبرتك ومهاراتك وبيانات التوفر.',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerProfilePage(
                    userId: workerId,
                    repository: WorkerRepository(
                      client ?? Supabase.instance.client,
                    ),
                  ),
                ),
              ),
            ),
            _ProviderAction(
              icon: Icons.history,
              title: 'سجل الأعمال والأرباح',
              subtitle: 'سيظهر هنا بعد إتمام أول خدمة.',
              onTap: () {},
            ),
            _ProviderAction(
              icon: Icons.support_agent_outlined,
              title: 'دعم سند',
              subtitle: 'تواصل مع فريق التشغيل عند الحاجة.',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    ),
  );
}

class _ProviderAction extends StatelessWidget {
  const _ProviderAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    ),
  );
}
