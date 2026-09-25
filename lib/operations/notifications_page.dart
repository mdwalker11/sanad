import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'operations_repository.dart';

/// مصدر الإشعارات الذي تعتمد عليه الشاشة.
///
/// يفصل الواجهة عن Supabase حتى يمكن اختبار كل الحالات دون شبكة.
abstract class NotificationsSource {
  Future<List<AppNotification>> fetch();
  Future<void> markRead(String id);
}

/// التنفيذ الفعلي المدعوم بـ Supabase.
class SupabaseNotificationsSource implements NotificationsSource {
  SupabaseNotificationsSource(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  OperationsRepository get _repo => OperationsRepository(client);

  @override
  Future<List<AppNotification>> fetch() async {
    final rows = await _repo.notifications(userId);
    return rows.map(AppNotification.fromRow).toList();
  }

  @override
  Future<void> markRead(String id) => _repo.markNotificationRead(id);
}

/// إشعار واحد.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromRow(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id']?.toString() ?? '',
      title: row['title_ar'] as String? ?? 'إشعار',
      body: row['body_ar'] as String? ?? '',
      isRead: row['read_at'] != null,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
    );
  }
}

/// يحوّل تاريخاً إلى نص عربي نسبي: "قبل 3 ساعات".
String relativeArabic(DateTime? then, {DateTime? now}) {
  if (then == null) return '';
  final diff = (now ?? DateTime.now()).difference(then);

  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    if (m == 1) return 'قبل دقيقة';
    if (m == 2) return 'قبل دقيقتين';
    if (m <= 10) return 'قبل $m دقائق';
    return 'قبل $m دقيقة';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    if (h == 1) return 'قبل ساعة';
    if (h == 2) return 'قبل ساعتين';
    if (h <= 10) return 'قبل $h ساعات';
    return 'قبل $h ساعة';
  }
  final d = diff.inDays;
  if (d == 1) return 'أمس';
  if (d == 2) return 'قبل يومين';
  if (d <= 10) return 'قبل $d أيام';
  return 'قبل $d يوماً';
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.source});

  /// يبني الشاشة بالمصدر الافتراضي المدعوم بـ Supabase.
  factory NotificationsPage.forUser(String userId, {Key? key}) {
    return NotificationsPage(
      key: key,
      source: SupabaseNotificationsSource(Supabase.instance.client, userId),
    );
  }

  final NotificationsSource source;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  String? _error;
  List<AppNotification> _items = const [];

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
      final data = await widget.source.fetch();
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الإشعارات. تحقق من الاتصال ثم أعد المحاولة.';
        _loading = false;
      });
    }
  }

  Future<void> _markRead(AppNotification item) async {
    if (item.isRead) return;
    try {
      await widget.source.markRead(item.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحديث حالة الإشعار')),
      );
      return;
    }
    if (!mounted) return;
    await _load();
  }

  Future<void> _markAllRead() async {
    final unread = _items.where((i) => !i.isRead).toList();
    for (final item in unread) {
      try {
        await widget.source.markRead(item.id);
      } catch (_) {
        // نكمل الباقي؛ فشل واحد لا يوقف الكل.
      }
    }
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((i) => !i.isRead).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            unreadCount > 0 ? 'الإشعارات ($unreadCount)' : 'الإشعارات',
          ),
          actions: [
            if (unreadCount > 0)
              TextButton(
                key: const Key('notifications_mark_all'),
                onPressed: _markAllRead,
                child: const Text('تعليم الكل كمقروء'),
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
        key: Key('notifications_loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        key: const Key('notifications_error'),
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
                  key: const Key('notifications_retry'),
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

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const Key('notifications_empty'),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('لا توجد إشعارات بعد')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        key: const Key('notifications_list'),
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            // غير المقروء يبرز بلون مختلف — تمييز بصري واضح.
            color: item.isRead
                ? null
                : Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              key: Key('notification_${item.id}'),
              onTap: item.isRead ? null : () => _markRead(item),
              leading: Icon(
                item.isRead
                    ? Icons.notifications_none_outlined
                    : Icons.notifications_active_outlined,
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.isRead
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              subtitle: Text(item.body),
              trailing: Text(
                relativeArabic(item.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
