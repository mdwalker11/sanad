import 'package:flutter/material.dart';

/// شاشة دعم سند — قنوات التواصل مع فريق التشغيل.
///
/// لا تعتمد على الشبكة إطلاقاً، لذا تعمل حتى عند انقطاع الاتصال،
/// وهو بالضبط الوقت الذي يحتاج فيه العامل إلى الدعم.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key, this.onContact});

  /// يُستدعى عند اختيار قناة تواصل. يُمرَّر في الاختبار للتحقق من الضغط.
  final void Function(SupportChannel channel)? onContact;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دعم سند')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فريق التشغيل في خدمتك',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'من السبت إلى الخميس، 9 صباحاً حتى 6 مساءً بتوقيت طرابلس.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'قنوات التواصل',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _ContactTile(
              tileKey: const Key('support_phone'),
              icon: Icons.phone_outlined,
              title: 'اتصال هاتفي',
              subtitle: 'للحالات العاجلة أثناء تنفيذ خدمة',
              onTap: () => onContact?.call(SupportChannel.phone),
            ),
            _ContactTile(
              tileKey: const Key('support_whatsapp'),
              icon: Icons.chat_outlined,
              title: 'واتساب',
              subtitle: 'الأسرع للاستفسارات العامة',
              onTap: () => onContact?.call(SupportChannel.whatsapp),
            ),
            _ContactTile(
              tileKey: const Key('support_email'),
              icon: Icons.mail_outline,
              title: 'البريد الإلكتروني',
              subtitle: 'للمستندات والشكاوى الرسمية',
              onTap: () => onContact?.call(SupportChannel.email),
            ),
            const SizedBox(height: 24),
            const Text(
              'أسئلة متكررة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._faq.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  key: Key('faq_${entry.$1}'),
                  title: Text(
                    entry.$2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        entry.$3,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قنوات التواصل المتاحة.
enum SupportChannel { phone, whatsapp, email }

const _faq = <(String, String, String)>[
  (
    'payout',
    'متى أستلم أرباحي؟',
    'تُحصَّل الأرباح نقداً عند إتمام الخدمة. يظهر صافي ربحك بعد خصم '
        'عمولة المنصة مباشرة في شاشة سجل الأعمال والأرباح.',
  ),
  (
    'commission',
    'كيف تُحسب عمولة سند؟',
    'العمولة نسبة ثابتة من قيمة الخدمة تُخصم تلقائياً، وتظهر مفصّلة '
        'لكل عملية في سجل الأرباح.',
  ),
  (
    'cancel',
    'ماذا أفعل إذا ألغى العميل الطلب؟',
    'الطلبات الملغاة لا تُحتسب ضمن أرباحك. إن أُلغي الطلب بعد وصولك '
        'للموقع، تواصل مع فريق التشغيل فوراً.',
  ),
  (
    'verify',
    'كيف أوثّق حسابي كعامل؟',
    'أكمل بياناتك في صفحة ملف العامل وأرفق المستندات المطلوبة. '
        'يراجعها فريق التشغيل خلال يوم عمل.',
  ),
];

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: tileKey,
        // منطقة لمس مريحة لا تقل عن 48 بكسل.
        minVerticalPadding: 12,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
